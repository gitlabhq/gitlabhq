module Gitlab
  module Prometheus
    module Queries
      class AdditionalMetricsDeploymentQuery < BaseQuery
        include QueryAdditionalMetrics

        def query(deployment_id)
          Deployment.find_by(id: deployment_id).try do |deployment|
            query_context = common_query_context(deployment.environment).merge(
              {
                timeframe_start: (deployment.created_at - 30.minutes).to_f,
                timeframe_end: (deployment.created_at + 30.minutes).to_f
              }
            )

            query_metrics(query_context)
          end
        end
      end
    end
  end
end
