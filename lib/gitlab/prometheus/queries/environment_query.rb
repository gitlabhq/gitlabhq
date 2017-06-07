module Gitlab::Prometheus::Queries
  class EnvironmentQuery < BaseQuery
    def query(environment_id)
      environment = Environment.find_by(id: environment_id)
      environment_slug = environment.slug
      timeframe_start = 8.hours.ago.to_f
      timeframe_end = Time.now.to_f

      memory_query = raw_memory_usage_query(environment_slug)
      cpu_query = raw_cpu_usage_query(environment_slug)

      {
        memory_values: client_query_range(memory_query, start: timeframe_start, stop: timeframe_end),
        memory_current: client_query(memory_query, time: timeframe_end),
        cpu_values: client_query_range(cpu_query, start: timeframe_start, stop: timeframe_end),
        cpu_current: client_query(cpu_query, time: timeframe_end)
      }
    end
  end
end
