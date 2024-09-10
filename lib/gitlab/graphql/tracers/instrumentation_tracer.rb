# frozen_string_literal: true

module Gitlab
  module Graphql
    module Tracers
      # This tracer writes logs for certain trace events.
      module InstrumentationTracer
        # All queries pass through a multiplex, even if only one query is executed
        # https://github.com/rmosolgo/graphql-ruby/blob/43e377b5b743a9102381d6ad3adaaed13ff5b6dd/lib/graphql/schema.rb#L1303
        #
        # Instrumenting the multiplex ensures that all queries have been fully exectued
        # meaning that `query.result` is present.
        # We need `query.result` to know if the query was successful or not in metrics and
        # to include the errors in the logs.
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
          has_errors = exception || query.result['errors'].present?

          ::Gitlab::ApplicationContext.with_context(caller_id: operation.to_caller_id) do
            log_execute_query(query: query, duration_s: duration_s, exception: exception)
            increment_query_sli(operation: operation, duration_s: duration_s, has_errors: has_errors)
          end
        end

        def increment_query_sli(operation:, duration_s:, has_errors:)
          query_urgency = operation.query_urgency
          labels = {
            endpoint_id: operation.to_caller_id,
            feature_category: ::Gitlab::ApplicationContext.current_context_attribute(:feature_category),
            query_urgency: query_urgency.name
          }

          Gitlab::Metrics::RailsSlis.graphql_query_error_rate.increment(
            labels: labels,
            error: has_errors
          )

          return if has_errors

          Gitlab::Metrics::RailsSlis.graphql_query_apdex.increment(
            labels: labels,
            success: duration_s <= query_urgency.duration
          )
        end

        def log_execute_query(query: nil, duration_s: 0, exception: nil)
          # execute_query should always have :query, but we're just being defensive
          return unless query

          analysis_info = query.context[:gl_analysis]&.transform_keys { |key| "query_analysis.#{key}" }
          info = {
            trace_type: 'execute_query',
            query_fingerprint: query.fingerprint,
            duration_s: duration_s,
            operation_name: query.operation_name,
            operation_fingerprint: query.operation_fingerprint,
            is_mutation: query.mutation?,
            variables: clean_variables(query.provided_variables),
            query_string: query.query_string
          }

          token_info = auth_token_info(query)
          info.merge!(token_info) if token_info

          info[:graphql_errors] = query.result['errors'] if query.result['errors']

          Gitlab::ExceptionLogFormatter.format!(exception, info)

          info.merge!(::Gitlab::ApplicationContext.current)
          info.merge!(analysis_info) if analysis_info

          ::Gitlab::GraphqlLogger.info(info)
        end

        def auth_token_info(query)
          request_env = query.context[:request]&.env
          return unless request_env

          request_env[::Gitlab::Auth::AuthFinders::API_TOKEN_ENV]
        end

        def clean_variables(variables)
          filtered = ActiveSupport::ParameterFilter
            .new(::Rails.application.config.filter_parameters)
            .filter(variables)

          filtered&.to_s
        end
      end
    end
  end
end
