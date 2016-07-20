module MergeRequests
  class MergeRequestDiffCacheService
    def execute(merge_request)
      # Executing the iteration we cache all the highlighted diff information
      SafeDiffs::MergeRequest.new(merge_request, diff_options: SafeDiffs.default_options).diff_files.to_a
    end
  end
end
