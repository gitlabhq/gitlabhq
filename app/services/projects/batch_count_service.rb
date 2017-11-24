module Projects
  class BatchCountService
    def initialize(projects)
      @projects = projects
    end

    def count
      @projects.map do |project|
        [project.id, current_count_service(project).count]
      end.to_h
    end

    def refresh_cache
      @projects.each do |project|
        unless current_count_service(project).count_stored?
          current_count_service(project).refresh_cache { global_count[project.id].to_i }
        end
      end
    end

    def current_count_service(project)
      if defined? @service
        @service.project = project
      else
        @service = count_service.new(project)
      end

      @service
    end

    def global_count(project)
      raise NotImplementedError, 'global_count must be implemented and return an hash indexed by the project id'
    end

    def count_service
      raise NotImplementedError, 'count_service must be implemented and return a Projects::CountService object'
    end
  end
end
