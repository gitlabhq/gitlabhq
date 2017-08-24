module Projects
  # Service class for getting and caching the number of forks of a project.
  class ForksCountService < CountService
    def relation_for_count
      @project.forks
    end

    def cache_key_name
      'forks_count'
    end
  end
end
