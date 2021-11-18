# frozen_string_literal: true

module Projects
  # Service class for counting and caching the number of all issues of a
  # project.
  class AllIssuesCountService < Projects::CountService
    def relation_for_count
      @project.issues
    end

    def cache_key_name
      'all_issues_count'
    end
  end
end
