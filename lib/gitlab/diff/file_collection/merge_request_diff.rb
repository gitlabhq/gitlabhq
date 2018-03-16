module Gitlab
  module Diff
    module FileCollection
      class MergeRequestDiff < Base
        def initialize(merge_request_diff, diff_options:)
          @merge_request_diff = merge_request_diff

          super(merge_request_diff,
            project: merge_request_diff.project,
            diff_options: diff_options,
            diff_refs: merge_request_diff.diff_refs,
            fallback_diff_refs: merge_request_diff.fallback_diff_refs)
        end

        def diff_files
          # Make sure to _not_ send any method call to Gitlab::Diff::File
          # _before_ all of them were collected (`super`). Premature method calls will
          # trigger N+1 RPCs to Gitaly through BatchLoader records (Blob.lazy).
          #
          diff_files = super

          diff_files.each { |diff_file| cache_highlight!(diff_file) if cacheable?(diff_file) }
          store_highlight_cache

          diff_files
        end

        def real_size
          @merge_request_diff.real_size
        end

        def clear_cache!
          Rails.cache.delete(cache_key)
        end

        def cache_key
          [@merge_request_diff, 'highlighted-diff-files', diff_options]
        end

        private

        def highlight_diff_file_from_cache!(diff_file, cache_diff_lines)
          diff_file.highlighted_diff_lines = cache_diff_lines.map do |line|
            Gitlab::Diff::Line.init_from_hash(line)
          end
        end

        #
        # If we find the highlighted diff files lines on the cache we replace existing diff_files lines (no highlighted)
        # for the highlighted ones, so we just skip their execution.
        # If the highlighted diff files lines are not cached we calculate and cache them.
        #
        # The content of the cache is a Hash where the key identifies the file and the values are Arrays of
        # hashes that represent serialized diff lines.
        #
        def cache_highlight!(diff_file)
          item_key = diff_file.file_identifier

          if highlight_cache[item_key]
            highlight_diff_file_from_cache!(diff_file, highlight_cache[item_key])
          else
            highlight_cache[item_key] = diff_file.highlighted_diff_lines.map(&:to_hash)
          end
        end

        def highlight_cache
          return @highlight_cache if defined?(@highlight_cache)

          @highlight_cache = Rails.cache.read(cache_key) || {}
          @highlight_cache_was_empty = @highlight_cache.empty?
          @highlight_cache
        end

        def store_highlight_cache
          Rails.cache.write(cache_key, highlight_cache, expires_in: 1.week) if @highlight_cache_was_empty
        end

        def cacheable?(diff_file)
          @merge_request_diff.present? && diff_file.text? && diff_file.diffable?
        end
      end
    end
  end
end
