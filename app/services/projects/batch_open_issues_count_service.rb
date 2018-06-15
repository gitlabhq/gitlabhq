# Service class for getting and caching the number of issues of several projects
# Warning: do not user this service with a really large set of projects
# because the service use maps to retrieve the project ids
module Projects
  class BatchOpenIssuesCountService < Projects::BatchCountService

    # Method not needed. Cache here is updated using
    # overloaded OpenIssuesCount#refresh_cache method
    def global_count
      nil
    end

    def count_service
      ::Projects::OpenIssuesCountService
    end
  end
end
