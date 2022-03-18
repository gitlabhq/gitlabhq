# frozen_string_literal: true
module Gitlab
  module Diff
    module Rendered
      module Notebook
        include Gitlab::Utils::StrongMemoize

        class DiffFile < Gitlab::Diff::File
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
              removal_line_maps, addition_line_maps = compute_end_start_map
              Gitlab::Diff::Highlight.new(self, repository: self.repository).highlight.map do |line|
                mutate_line(line, addition_line_maps, removal_line_maps)
              end
            end
          end

          private

          def notebook_diff
            strong_memoize(:notebook_diff) do
              Gitlab::AppLogger.info({ message: 'IPYNB_DIFF_GENERATED' })

              IpynbDiff.diff(source_diff.old_blob&.data, source_diff.new_blob&.data,
                             raise_if_invalid_nb: true,
                             diffy_opts: { include_diff_info: true })
            rescue IpynbDiff::InvalidNotebookError, IpynbDiff::InvalidTokenError => e
              Gitlab::ErrorTracking.log_exception(e)
              nil
            end
          end

          def transformed_diff
            return unless notebook_diff

            diff = source_diff.diff.clone
            diff.diff = strip_diff_frontmatter(notebook_diff.to_s(:text))
            diff
          end

          def strip_diff_frontmatter(diff_content)
            diff_content.scan(/.*\n/)[2..]&.join('') if diff_content.present?
          end

          def transformed_line_to_source(transformed_line, transformed_blocks)
            transformed_blocks.empty? ? 0 : ( transformed_blocks[transformed_line - 1][:source_line] || -1 ) + 1
          end

          def mutate_line(line, addition_line_maps, removal_line_maps)
            line.new_pos = transformed_line_to_source(line.new_pos, notebook_diff.to.blocks)
            line.old_pos = transformed_line_to_source(line.old_pos, notebook_diff.from.blocks)

            line.old_pos = addition_line_maps[line.new_pos] if line.old_pos == 0 && line.new_pos != 0
            line.new_pos = removal_line_maps[line.old_pos] if line.new_pos == 0 && line.old_pos != 0

            # Lines that do not appear on the original diff should not be commentable

            unless addition_line_maps[line.new_pos] || removal_line_maps[line.old_pos]
              line.discussable = false
            end

            line.line_code = line_code(line)
            line
          end

          def compute_end_start_map
            # line_codes are used for assigning notes to diffs, and these depend on the line on the new version and the
            # line that would have been that one in the previous version. However, since we do a transformation on the
            # file, that map gets lost. To overcome this, we look at the original source lines and build two maps:
            # - For additions, we look at the latest line change for that line and pick the old line for that id
            # - For removals, we look at the first line in the old version, and pick the first line on the new version
            #
            #
            # The caveat here is that we can't have notes on lines that are not a translation of a line in the source
            # diff
            #
            # (gitlab/diff/file.rb:75)

            removals = {}
            additions = {}

            source_diff.highlighted_diff_lines.each do |line|
              removals[line.old_pos] = line.new_pos
              additions[line.new_pos] = line.old_pos
            end

            [removals, additions]
          end
        end
      end
    end
  end
end
