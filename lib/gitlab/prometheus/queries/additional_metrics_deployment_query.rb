module Gitlab
  module Prometheus
    module Queries
      class AdditionalMetricsDeploymentQuery < BaseQuery
        include QueryAdditionalMetrics

        def query(deployment_id)
          Deployment.find_by(id: deployment_id).try do |deployment|
            query_context = {
              environment_slug: deployment.environment.slug,
              environment_filter: %{container_name!="POD",environment="#{deployment.environment.slug}"},
              timeframe_start: (deployment.created_at - 30.minutes).to_f,
              timeframe_end: (deployment.created_at + 30.minutes).to_f
            }

            query_metrics(query_context)
          end
        end
      end
    end
  end
end
