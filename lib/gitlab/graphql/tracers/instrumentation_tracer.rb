# frozen_string_literal: true

module Gitlab
  module Graphql
    module Tracers
      # This tracer writes logs for certain trace events.
      module InstrumentationTracer
        IGNORED_ERRORS = [
          ::Subscriptions::BaseSubscription::UNAUTHORIZED_ERROR_MESSAGE
        ].freeze

        # All queries pass through a multiplex, even if only one query is executed
        # https://github.com/rmosolgo/graphql-ruby/blob/43e377b5b743a9102381d6ad3adaaed13ff5b6dd/lib/graphql/schema.rb#L1303
        #
        # Hooking the multiplex rather than `execute_query` means even queries that failed
        # validation reach here with `query.result` set; `result_errors` covers the exception.
        def execute_multiplex(multiplex:)
          start_time = ::Gitlab::Metrics::System.monotonic_time
          super
        rescue StandardError => e
          raise
        ensure
          duration_s = ::Gitlab::Metrics::System.monotonic_time - start_time

          multiplex.queries.each do |query|
            export_query_info(query: query, duration_s: duration_s, exception: e)
          end
        end

        private

        def export_query_info(query:, duration_s:, exception:)
          operation = ::Gitlab::Graphql::KnownOperations.default.from_query(query)
          error_type = error_type(query: query, exception: exception)

          ::Gitlab::ApplicationContext.with_context(caller_id: operation.to_caller_id) do
            log_execute_query(query: query, duration_s: duration_s, exception: exception)
            increment_query_sli(operation: operation, duration_s: duration_s, error_type: error_type)
          end
        end

        def increment_query_sli(operation:, duration_s:, error_type:)
          query_urgency = operation.query_urgency
          labels = {
            endpoint_id: operation.to_caller_id,
            feature_category: ::Gitlab::ApplicationContext.current_context_attribute(:feature_category),
            query_urgency: query_urgency.name
          }

          Gitlab::Metrics::RailsSlis.graphql_query_error_rate.increment(
            labels: labels,
            error: error_type == :error
          )

          return if error_type

          Gitlab::Metrics::RailsSlis.graphql_query_apdex.increment(
            labels: labels,
            success: duration_s <= query_urgency.duration
          )
        end

        def error_type(query:, exception:)
          return :error if exception || !query.executed?

          errors = result_errors(query)&.pluck('message')

          return if errors.blank?

          if (errors - IGNORED_ERRORS).present?
            :error
          else
            :ignored
          end
        end

        def log_execute_query(query: nil, duration_s: 0, exception: nil)
          # execute_query should always have :query, but we're just being defensive
          return unless query

          analysis_info = query.context[:gl_analysis]&.transform_keys { |key| "query_analysis.#{key}" }
          logging = query.context.namespace(:gl_logging)
          connection_nodes = logging.fetch(:connection_nodes, 0)
          logging[:request_log]&.store(Labkit::Fields::GRAPHQL_CONNECTION_NODES, connection_nodes)

          info = {
            query_fingerprint: query.fingerprint,
            duration_s: duration_s,
            operation_name: query.operation_name,
            operation_fingerprint: query.operation_fingerprint,
            is_mutation: query.mutation?,
            Labkit::Fields::GRAPHQL_CONNECTION_NODES => connection_nodes,
            variables: ::Gitlab::Graphql::LogSanitizer.variables(query.provided_variables, query.operation_name),
            query_string: ::Gitlab::Graphql::LogSanitizer.query_string(query)
          }

          token_info = ::Current.token_info
          info.merge!(token_info) if token_info

          graphql_errors = result_errors(query)
          info[:graphql_errors] = graphql_errors if graphql_errors

          Gitlab::ExceptionLogFormatter.format!(exception, info)

          info.merge!(::Gitlab::ApplicationContext.current)
          info.merge!(analysis_info) if analysis_info

          ::Gitlab::GraphqlLogger.info(info)
        end

        # `query.result` executes the query if it hasn't run yet. We only want to read errors,
        # not trigger execution, so skip queries that never executed (e.g. analysis raised).
        # ref: https://www.rubydoc.info/github/rmosolgo/graphql-ruby/GraphQL/Query#result-instance_method
        def result_errors(query)
          query.result['errors'] if query.executed?
        end
      end
    end
  end
end
