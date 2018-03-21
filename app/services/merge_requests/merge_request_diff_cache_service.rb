module MergeRequests
  class MergeRequestDiffCacheService
    def execute(merge_request, new_diff)
      # Executing the iteration we cache all the highlighted diff information
      merge_request.diffs.diff_files.to_a

      # Remove cache for all diffs on this MR. Do not use the association on the
      # model, as that will interfere with other actions happening when
      # reloading the diff.
      MergeRequestDiff.where(merge_request: merge_request).each do |merge_request_diff|
        next if merge_request_diff == new_diff

        merge_request_diff.diffs.clear_cache!
      end
    end
  end
end
