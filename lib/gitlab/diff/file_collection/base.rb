# frozen_string_literal: true

module Gitlab
  module Diff
    module FileCollection
      class Base
        include Gitlab::Utils::StrongMemoize

        attr_reader :project, :diff_options, :diff_refs, :fallback_diff_refs, :diffable

        delegate :count, :size, :real_size, to: :raw_diff_files

        def self.default_options
          ::Commit.max_diff_options.merge(ignore_whitespace_change: false, expanded: false, include_stats: true)
        end

        def initialize(diffable, project:, diff_options: nil, diff_refs: nil, fallback_diff_refs: nil)
          diff_options = self.class.default_options.merge(diff_options || {})

          @diffable = diffable
          @include_stats = diff_options.delete(:include_stats)
          @pagination_data = diff_options.delete(:pagination_data)
          @project = project
          @diff_options = diff_options
          @diff_refs = diff_refs
          @fallback_diff_refs = fallback_diff_refs
          @repository = project.repository
        end

        def diffs
          @diffs ||= diffable.raw_diffs(diff_options)
        end

        def diff_files(sorted: false)
          raw_diff_files(sorted: sorted)
        end

        def raw_diff_files(sorted: false)
          strong_memoize(:"raw_diff_files_#{sorted}") do
            collection = diffs.decorate! { |diff| decorate_diff!(diff) }
            collection = sort_diffs(collection) if sorted
            collection
          end
        end

        def diff_file_paths
          diff_files.map(&:file_path)
        end

        def pagination_data
          @pagination_data || empty_pagination_data
        end

        # This mutates `diff_files` lines.
        def unfold_diff_files(positions)
          positions_grouped_by_path = positions.group_by { |position| position.file_path }

          diff_files.each do |diff_file|
            positions = positions_grouped_by_path.fetch(diff_file.file_path, [])
            positions.each { |position| diff_file.unfold_diff_lines(position) }
          end
        end

        def diff_file_with_old_path(old_path, a_mode = nil)
          if Feature.enabled?(:file_identifier_hash) && a_mode.present?
            diff_files.find { |diff_file| diff_file.old_path == old_path && diff_file.a_mode == a_mode }
          else
            diff_files.find { |diff_file| diff_file.old_path == old_path }
          end
        end

        def diff_file_with_new_path(new_path, b_mode = nil)
          if Feature.enabled?(:file_identifier_hash) && b_mode.present?
            diff_files.find { |diff_file| diff_file.new_path == new_path && diff_file.b_mode == b_mode }
          else
            diff_files.find { |diff_file| diff_file.new_path == new_path }
          end
        end

        def clear_cache
          # No-op
        end

        def write_cache
          # No-op
        end

        def overflow?
          raw_diff_files.overflow?
        end

        private

        def empty_pagination_data
          { total_pages: nil }
        end

        def diff_stats_collection
          strong_memoize(:diff_stats) do
            next unless fetch_diff_stats?

            @repository.diff_stats(diff_refs.base_sha, diff_refs.head_sha)
          end
        end

        def fetch_diff_stats?
          # There are scenarios where we don't need to request Diff Stats,
          # when caching for instance.
          @include_stats && diff_refs
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

        def sort_diffs(diffs)
          Gitlab::Diff::FileCollectionSorter.new(diffs).sort
        end
      end
    end
  end
end
