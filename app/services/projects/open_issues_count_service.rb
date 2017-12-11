module Projects
  # Service class for counting and caching the number of open issues of a
  # project.
  class OpenIssuesCountService < Projects::CountService
    def cache_key_name
      'open_issues_count'
    end

    def self.query(project_ids)
      # We don't include confidential issues in this number since this would
      # expose the number of confidential issues to non project members.
      Issue.opened.public_only.where(project: project_ids)
    end
  end
end
