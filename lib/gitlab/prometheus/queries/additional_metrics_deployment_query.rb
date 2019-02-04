# frozen_string_literal: true

module Gitlab
  module Prometheus
    module Queries
      class AdditionalMetricsDeploymentQuery < BaseQuery
        include QueryAdditionalMetrics

        # rubocop: disable CodeReuse/ActiveRecord
        def query(deployment_id)
          Deployment.find_by(id: deployment_id).try do |deployment|
            query_metrics(
              deployment.project,
              deployment.environment,
              common_query_context(
                deployment.environment,
                timeframe_start: (deployment.created_at - 30.minutes).to_f,
                timeframe_end: (deployment.created_at + 30.minutes).to_f
              )
            )
          end
        end
        # rubocop: enable CodeReuse/ActiveRecord
      end
    end
  end
end
