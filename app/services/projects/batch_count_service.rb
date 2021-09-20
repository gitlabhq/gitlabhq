# frozen_string_literal: true

# Service class for getting and caching the number of elements of several projects
# Warning: do not user this service with a really large set of projects
# because the service use maps to retrieve the project ids.
module Projects
  class BatchCountService
    def initialize(projects)
      @projects = projects
    end

    def refresh_cache_and_retrieve_data
      count_services = @projects.map { |project| count_service.new(project) }
      services_by_cache_key = count_services.index_by(&:cache_key)

      results = Gitlab::Instrumentation::RedisClusterValidator.allow_cross_slot_commands do
        Rails.cache.fetch_multi(*services_by_cache_key.keys) do |key|
          service = services_by_cache_key[key]

          global_count[service.project.id].to_i
        end
      end

      results.transform_keys! { |cache_key| services_by_cache_key[cache_key].project }
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
