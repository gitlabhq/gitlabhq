module Projects
  # Service class for getting and caching the number of forks of several projects
  class BatchOpenIssuesCountService < Projects::BatchCountService
    def global_count
      @global_count ||= Issue.opened.public_only
                             .where(project: @projects.map(&:id))
                             .group(:project_id)
                             .count
    end

    def count_service
      ::Projects::OpenIssuesCountService
    end
  end
end
