module Projects
  # Service class for getting and caching the number of forks of several projects
  class BatchForksCountService < Projects::BatchCountService
    def global_count
      @global_count ||= begin
        count_service.query(project_ids)
                     .group(:forked_from_project_id)
                     .count
      end
    end

    def count_service
      ::Projects::ForksCountService
    end
  end
end
