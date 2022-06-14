# frozen_string_literal: true
module Gitlab
  module Diff
    module Rendered
      module Notebook
        class DiffFile < Gitlab::Diff::File
          include Gitlab::Diff::Rendered::Notebook::DiffFileHelper
          include Gitlab::Utils::StrongMemoize

          RENDERED_TIMEOUT_BACKGROUND = 10.seconds
          RENDERED_TIMEOUT_FOREGROUND = 1.5.seconds
          BACKGROUND_EXECUTION = 'background'
          FOREGROUND_EXECUTION = 'foreground'
          LOG_IPYNBDIFF_GENERATED = 'IPYNB_DIFF_GENERATED'
          LOG_IPYNBDIFF_TIMEOUT = 'IPYNB_DIFF_TIMEOUT'
          LOG_IPYNBDIFF_INVALID = 'IPYNB_DIFF_INVALID'
          LOG_IPYNBDIFF_TRUNCATED = 'IPYNB_DIFF_TRUNCATED'

          attr_reader :source_diff

          delegate :repository, :diff_refs, :fallback_diff_refs, :unfolded, :unique_identifier,
                   to: :source_diff

          def initialize(diff_file)
            @source_diff = diff_file
          end

          def old_blob
            return unless notebook_diff

            strong_memoize(:old_blob) { ::Blobs::Notebook.decorate(source_diff.old_blob, notebook_diff.from.as_text) }
          end

          def new_blob
            return unless notebook_diff

            strong_memoize(:new_blob) { ::Blobs::Notebook.decorate(source_diff.new_blob, notebook_diff.to.as_text) }
          end

          def diff
            strong_memoize(:diff) { transformed_diff }
          end

          def has_renderable?
            !notebook_diff.nil? && diff.diff.present?
          end

          def rendered
            self
          end

          def highlighted_diff_lines
            @highlighted_diff_lines ||= begin
              removal_line_maps, addition_line_maps = map_diff_block_to_source_line(
                source_diff.highlighted_diff_lines, source_diff.new_file?, source_diff.deleted_file?)
              Gitlab::Diff::Highlight.new(self, repository: self.repository).highlight.map do |line|
                mutate_line(line, addition_line_maps, removal_line_maps)
              end
            end
          end

          private

          def notebook_diff
            strong_memoize(:notebook_diff) do
              if source_diff.old_blob&.truncated? || source_diff.new_blob&.truncated?
                log_event(LOG_IPYNBDIFF_TRUNCATED)
                next
              end

              Timeout.timeout(timeout_time) do
                IpynbDiff.diff(source_diff.old_blob&.data, source_diff.new_blob&.data,
                               raise_if_invalid_nb: true,
                               diffy_opts: { include_diff_info: true })&.tap do
                  log_event(LOG_IPYNBDIFF_GENERATED)
                end
              end
            rescue Timeout::Error => e
              rendered_timeout.increment(source: Gitlab::Runtime.sidekiq? ? BACKGROUND_EXECUTION : FOREGROUND_EXECUTION)
              log_event(LOG_IPYNBDIFF_TIMEOUT, e)
            rescue IpynbDiff::InvalidNotebookError, IpynbDiff::InvalidTokenError => e
              log_event(LOG_IPYNBDIFF_INVALID, e)
            end
          end

          def transformed_diff
            return unless notebook_diff

            diff = source_diff.diff.clone
            diff.diff = strip_diff_frontmatter(notebook_diff.to_s(:text))
            diff
          end

          def rendered_timeout
            @rendered_timeout ||= Gitlab::Metrics.counter(
              :ipynb_semantic_diff_timeouts_total,
              'Counts the times notebook diff rendering timed out'
            )
          end

          def timeout_time
            Gitlab::Runtime.sidekiq? ? RENDERED_TIMEOUT_BACKGROUND : RENDERED_TIMEOUT_FOREGROUND
          end

          def log_event(message, error = nil)
            Gitlab::AppLogger.info({ message: message })
            Gitlab::ErrorTracking.log_exception(error) if error
            nil
          end

          def compute_line_numbers(transformed_old_pos, transformed_new_pos, addition_line_maps, removal_line_maps)
            new_pos = map_transformed_line_to_source(transformed_new_pos, notebook_diff.to.blocks)
            old_pos = map_transformed_line_to_source(transformed_old_pos, notebook_diff.from.blocks)

            old_pos = addition_line_maps[new_pos] if old_pos == 0 && new_pos != 0
            new_pos = removal_line_maps[old_pos] if new_pos == 0 && old_pos != 0

            [old_pos, new_pos]
          end

          def mutate_line(line, addition_line_maps, removal_line_maps)
            line.old_pos, line.new_pos = compute_line_numbers(line.old_pos, line.new_pos, addition_line_maps, removal_line_maps)

            # Lines that do not appear on the original diff should not be commentable
            line.type = "#{line.type || 'unchanged'}-nomappinginraw" unless addition_line_maps[line.new_pos] || removal_line_maps[line.old_pos]

            line.line_code = line_code(line)

            line.rich_text = image_as_rich_text(line.text) || line.rich_text

            line
          end
        end
      end
    end
  end
end
