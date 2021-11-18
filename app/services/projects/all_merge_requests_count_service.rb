# frozen_string_literal: true

module Projects
  # Service class for counting and caching the number of all merge requests of
  # a project.
  class AllMergeRequestsCountService < Projects::CountService
    def relation_for_count
      @project.merge_requests
    end

    def cache_key_name
      'all_merge_requests_count'
    end
  end
end
