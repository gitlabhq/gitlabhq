module Projects
  # Service class for counting and caching the number of open issues of a
  # project.
  class OpenIssuesCountService < Projects::CountService
    def relation_for_count
      # We don't include confidential issues in this number since this would
      # expose the number of confidential issues to non project members.
      @project.issues.opened.public_only
    end

    def cache_key_name
      'open_issues_count'
    end
  end
end
