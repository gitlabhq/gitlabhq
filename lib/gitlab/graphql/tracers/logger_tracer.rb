# frozen_string_literal: true

module Gitlab
  module Graphql
    module Tracers
      # This tracer writes logs for certain trace events.
      module LoggerTracer
        def execute_query(query:)
          start_time = ::Gitlab::Metrics::System.monotonic_time

          super
        rescue StandardError => e
          raise e
        ensure
          duration_s = ::Gitlab::Metrics::System.monotonic_time - start_time

          log_execute_query(query: query, duration_s: duration_s, exception: e)
        end

        private

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
