module Projects
  # Service class for getting and caching the number of forks of a project.
  class ForksCountService
    def initialize(project)
      @project = project
    end

    def count
      Rails.cache.fetch(cache_key) { uncached_count }
    end

    def refresh_cache
      Rails.cache.write(cache_key, uncached_count)
    end

    def delete_cache
      Rails.cache.delete(cache_key)
    end

    private

    def uncached_count
      @project.forks.count
    end

    def cache_key
      ['projects', @project.id, 'forks_count']
    end
  end
end
