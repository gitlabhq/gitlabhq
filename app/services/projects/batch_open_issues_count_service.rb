# Service class for getting and caching the number of issues of several projects
# Warning: do not user this service with a really large set of projects
# because the service use maps to retrieve the project ids
module Projects
  class BatchOpenIssuesCountService < Projects::BatchCountService
    def global_count
      @global_count ||= begin
        count_service.query(project_ids).group(:project_id).count
      end
    end

    def count_service
      ::Projects::OpenIssuesCountService
    end
  end
end
