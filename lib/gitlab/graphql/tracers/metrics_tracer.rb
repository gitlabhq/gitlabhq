# frozen_string_literal: true

module Gitlab
  module Graphql
    module Tracers
      module MetricsTracer
        def execute_query(query:)
          start_time = ::Gitlab::Metrics::System.monotonic_time

          super

          duration_s = ::Gitlab::Metrics::System.monotonic_time - start_time

          increment_query_sli(query: query, duration_s: duration_s)
        end

        private

        def increment_query_sli(query:, duration_s:)
          operation = ::Gitlab::Graphql::KnownOperations.default.from_query(query)
          query_urgency = operation.query_urgency

          Gitlab::Metrics::RailsSlis.graphql_query_apdex.increment(
            labels: {
              endpoint_id: ::Gitlab::ApplicationContext.current_context_attribute(:caller_id),
              feature_category: ::Gitlab::ApplicationContext.current_context_attribute(:feature_category),
              query_urgency: query_urgency.name
            },
            success: duration_s <= query_urgency.duration
          )
        end
      end
    end
  end
end
