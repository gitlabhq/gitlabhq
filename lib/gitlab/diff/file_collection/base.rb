# frozen_string_literal: true

module Gitlab
  module Diff
    module FileCollection
      class Base
        include Gitlab::Utils::StrongMemoize

        attr_reader :project, :diff_options, :diff_refs, :fallback_diff_refs, :diffable

        delegate :count, :size, :real_size, to: :diff_files

        def self.default_options
          ::Commit.max_diff_options.merge(ignore_whitespace_change: false, expanded: false, include_stats: true)
        end

        def initialize(diffable, project:, diff_options: nil, diff_refs: nil, fallback_diff_refs: nil)
          diff_options = self.class.default_options.merge(diff_options || {})

          @diffable = diffable
          @include_stats = diff_options.delete(:include_stats)
          @project = project
          @diff_options = diff_options
          @diff_refs = diff_refs
          @fallback_diff_refs = fallback_diff_refs
          @repository = project.repository
        end

        def diffs
          @diffs ||= diffable.raw_diffs(diff_options)
        end

        def diff_files
          raw_diff_files
        end

        def raw_diff_files
          @raw_diff_files ||= diffs.decorate! { |diff| decorate_diff!(diff) }
        end

        def diff_file_paths
          diff_files.map(&:file_path)
        end

        def pagination_data
          {
            current_page: nil,
            next_page: nil,
            total_pages: nil
          }
        end

        # This mutates `diff_files` lines.
        def unfold_diff_files(positions)
          positions_grouped_by_path = positions.group_by { |position| position.file_path }

          diff_files.each do |diff_file|
            positions = positions_grouped_by_path.fetch(diff_file.file_path, [])
            positions.each { |position| diff_file.unfold_diff_lines(position) }
          end
        end

        def diff_file_with_old_path(old_path)
          diff_files.find { |diff_file| diff_file.old_path == old_path }
        end

        def diff_file_with_new_path(new_path)
          diff_files.find { |diff_file| diff_file.new_path == new_path }
        end

        def clear_cache
          # No-op
        end

        def write_cache
          # No-op
        end

        private

        def diff_stats_collection
          strong_memoize(:diff_stats) do
            # There are scenarios where we don't need to request Diff Stats,
            # when caching for instance.
            next unless @include_stats
            next unless diff_refs

            @repository.diff_stats(diff_refs.base_sha, diff_refs.head_sha)
          end
        end

        def decorate_diff!(diff)
          return diff if diff.is_a?(File)

          stats = diff_stats_collection&.find_by_path(diff.new_path)

          Gitlab::Diff::File.new(diff,
                                 repository: project.repository,
                                 diff_refs: diff_refs,
                                 fallback_diff_refs: fallback_diff_refs,
                                 stats: stats)
        end
      end
    end
  end
end
