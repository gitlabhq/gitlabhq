module Gitlab
  module Prometheus
    module Queries
      class AdditionalMetricsEnvironmentQuery < BaseQuery
        include QueryAdditionalMetrics

        def query(environment_id)
          Environment.find_by(id: environment_id).try do |environment|
            query_context = {
              environment_slug: environment.slug,
              environment_filter: %{container_name!="POD",environment="#{environment.slug}"},
              timeframe_start: 8.hours.ago.to_f,
              timeframe_end: Time.now.to_f
            }

            query_metrics(query_context)
          end
        end
      end
    end
  end
end
