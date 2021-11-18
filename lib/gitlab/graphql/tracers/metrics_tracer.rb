# frozen_string_literal: true

module Gitlab
  module Graphql
    module Tracers
      class MetricsTracer
        def self.use(schema)
          schema.tracer(self.new)
        end

        # See https://graphql-ruby.org/api-doc/1.12.16/GraphQL/Tracing for full list of events
        def trace(key, data)
          result = yield

          case key
          when "execute_query"
            increment_query_sli(data)
          end

          result
        end

        private

        def increment_query_sli(data)
          duration_s = data.fetch(:duration_s, nil)
          query = data.fetch(:query, nil)

          # We're just being defensive here...
          # duration_s comes from TimerTracer and we should be pretty much guaranteed it exists
          return unless duration_s && query

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
