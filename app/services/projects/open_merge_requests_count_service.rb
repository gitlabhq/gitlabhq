module Projects
  # Service class for counting and caching the number of open merge requests of
  # a project.
  class OpenMergeRequestsCountService < Projects::CountService
    def relation_for_count
      @project.merge_requests.opened
    end

    def cache_key_name
      'open_merge_requests_count'
    end
  end
end
