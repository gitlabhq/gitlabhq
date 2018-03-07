module Gitlab
  module Prometheus
    module Queries
      class DeploymentQuery < BaseQuery
        def query(deployment_id)
          Deployment.find_by(id: deployment_id).try do |deployment|
            environment_slug = deployment.environment.slug

            memory_query = raw_memory_usage_query(environment_slug)
            memory_avg_query = %{avg(avg_over_time(container_memory_usage_bytes{container_name!="POD",environment="#{environment_slug}"}[30m]))}
            cpu_query = raw_cpu_usage_query(environment_slug)
            cpu_avg_query = %{avg(rate(container_cpu_usage_seconds_total{container_name!="POD",environment="#{environment_slug}"}[30m])) * 100}

            timeframe_start = (deployment.created_at - 30.minutes).to_f
            timeframe_end = (deployment.created_at + 30.minutes).to_f

            {
              memory_values: client_query_range(memory_query, start: timeframe_start, stop: timeframe_end),
              memory_before: client_query(memory_avg_query, time: deployment.created_at.to_f),
              memory_after: client_query(memory_avg_query, time: timeframe_end),

              cpu_values: client_query_range(cpu_query, start: timeframe_start, stop: timeframe_end),
              cpu_before: client_query(cpu_avg_query, time: deployment.created_at.to_f),
              cpu_after: client_query(cpu_avg_query, time: timeframe_end)
            }
          end
        end

        def self.transform_reactive_result(result)
          result[:metrics] = result.delete :data
          result
        end
      end
    end
  end
end
