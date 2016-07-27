module MergeRequests
  class MergeRequestDiffCacheService
    def execute(merge_request)
      # Executing the iteration we cache all the highlighted diff information
      merge_request.diff_file_collection.diff_files.to_a
    end
  end
end
