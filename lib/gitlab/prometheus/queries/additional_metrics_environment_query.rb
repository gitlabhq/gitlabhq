module Gitlab
  module Prometheus
    module Queries
      class AdditionalMetricsEnvironmentQuery < BaseQuery
        include QueryAdditionalMetrics

        def query(environment_id)
          Environment.find_by(id: environment_id).try do |environment|
            query_context = common_query_context(environment).merge(
              {
                timeframe_start: 8.hours.ago.to_f,
                timeframe_end: Time.now.to_f
              }
            )

            query_metrics(query_context)
          end
        end
      end
    end
  end
end
