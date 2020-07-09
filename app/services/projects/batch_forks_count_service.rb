# frozen_string_literal: true

# Service class for getting and caching the number of forks of several projects
# Warning: do not user this service with a really large set of projects
# because the service use maps to retrieve the project ids
module Projects
  class BatchForksCountService < Projects::BatchCountService
    def refresh_cache_and_retrieve_data
      count_services = @projects.map { |project| count_service.new(project) }

      values = Gitlab::Instrumentation::RedisClusterValidator.allow_cross_slot_commands do
        Rails.cache.fetch_multi(*(count_services.map { |ser| ser.cache_key } )) { |key| nil }
      end

      results_per_service = Hash[count_services.zip(values.values)]
      projects_to_refresh = results_per_service.select { |_k, value| value.nil? }
      projects_to_refresh = recreate_cache(projects_to_refresh)

      results_per_service.update(projects_to_refresh)
      results_per_service.transform_keys { |k| k.project }
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def global_count
      @global_count ||= begin
        count_service.query(project_ids)
                     .group(:forked_from_project_id)
                     .count
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def count_service
      ::Projects::ForksCountService
    end

    def recreate_cache(projects_to_refresh)
      projects_to_refresh.each_with_object({}) do |(service, _v), hash|
        count = global_count[service.project.id].to_i
        service.refresh_cache { count }
        hash[service] = count
      end
    end
  end
end
