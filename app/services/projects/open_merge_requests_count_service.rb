# frozen_string_literal: true

module Projects
  # Service class for counting and caching the number of open merge requests of
  # a project.
  class OpenMergeRequestsCountService < Projects::CountService
    def cache_key_name
      'open_merge_requests_count'
    end

    def self.query(project_ids)
      MergeRequest.opened.of_projects(project_ids)
    end
  end
end
