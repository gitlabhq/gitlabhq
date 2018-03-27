# Service class for getting and caching the number of elements of several projects
# Warning: do not user this service with a really large set of projects
# because the service use maps to retrieve the project ids.
module Projects
  class BatchCountService
    def initialize(projects)
      @projects = projects
    end

    def refresh_cache
      @projects.each do |project|
        service = count_service.new(project)
        unless service.count_stored?
          service.refresh_cache { global_count[project.id].to_i }
        end
      end
    end

    def project_ids
      @projects.map(&:id)
    end

    def global_count(project)
      raise NotImplementedError, 'global_count must be implemented and return an hash indexed by the project id'
    end

    def count_service
      raise NotImplementedError, 'count_service must be implemented and return a Projects::CountService object'
    end
  end
end
