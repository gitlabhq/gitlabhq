module SafeDiffs
  class MergeRequest < Base
    def initialize(merge_request, diff_options:)
      @merge_request = merge_request

      super(merge_request.diffs(diff_options),
        project: merge_request.project,
        diff_options: diff_options,
        diff_refs: merge_request.diff_refs)
    end

    private

    #
    # If we find the highlighted diff files lines on the cache we replace existing diff_files lines (no highlighted)
    # for the highlighted ones, so we just skip their execution.
    # If the highlighted diff files lines are not cached we calculate and cache them.
    #
    # The content of the cache is and Hash where the key correspond to the file_path and the values are Arrays of
    # hashes than represent serialized diff lines.
    #
    def cache_highlight!(diff_files)
      highlighted_cache = Rails.cache.read(cache_key) || {}
      highlighted_cache_was_empty = highlighted_cache.empty?

      diff_files.each do |diff_file|
        file_path = diff_file.file_path

        if highlighted_cache[file_path]
          highlight_diff_file_from_cache!(diff_file, highlighted_cache[file_path])
        else
          highlight_diff_file!(diff_file)
          highlighted_cache[file_path] = diff_file.diff_lines.map(&:to_hash)
        end
      end

      if highlighted_cache_was_empty
        Rails.cache.write(cache_key, highlighted_cache)
      end

      diff_files
    end

    def cacheable?
      @merge_request.merge_request_diff.present?
    end

    def cache_key
      [@merge_request.merge_request_diff, 'highlighted-safe-diff-files', diff_options]
    end
  end
end
