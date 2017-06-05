module Gitlab::Prometheus::Queries
  class AdditionalMetricsDeploymentQuery < AdditionalMetricsQuery
    def query(deployment_id)
      deployment = Deployment.find_by(id: deployment_id)
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
