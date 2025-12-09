# frozen_string_literal: true

module Analytics
  module Glql
    # Service for logging GLQL/GraphQL execution metrics and performance data
    # Logs to GraphQL logger for monitoring, optimization, and debugging
    # Used by both REST API::Glql (with GLQL-specific details) and Glql::BaseController (GraphQL only)
    class LoggingService
      def initialize(
        current_user:, result:, query_sha:, glql_query: nil, generated_graphql: nil, fields: nil,
        context: nil)
        @current_user = current_user
        @result = result
        @query_sha = query_sha
        @glql_query = glql_query
        @generated_graphql = generated_graphql
        @fields = fields
        @context = context
      end

      def execute
        log_timeout if timeout_occurred?
        log_high_complexity if high_complexity?
        log_slow_query if slow_query?
      end

      private

      attr_reader :current_user, :result, :query_sha, :glql_query, :generated_graphql, :fields, :context

      def timeout_occurred?
        result[:timeout_occurred]
      end

      def high_complexity?
        complexity_score && complexity_score > 100
      end

      def slow_query?
        duration_s && duration_s > 5.0
      end

      def complexity_score
        result[:complexity_score]
      end

      def duration_s
        result[:duration_s]
      end

      def base_log_data
        data = {
          query_sha: query_sha,
          complexity_score: complexity_score,
          user_id: current_user&.id
        }

        # Add GLQL-specific details if available (REST API path)
        if glql_query
          data[:glql_query] = glql_query
          data[:generated_graphql] = generated_graphql
          data[:fields] = fields
          data[:context] = context
        end

        data
      end

      def log_timeout
        Gitlab::GraphqlLogger.warn(
          base_log_data.merge(
            message: 'GLQL GraphQL query timeout'
          )
        )
      end

      def log_high_complexity
        Gitlab::GraphqlLogger.info(
          base_log_data.merge(
            message: 'GLQL high complexity query detected - Duo optimization needed',
            duration_s: duration_s,
            optimization_needed: complexity_score > 200
          )
        )
      end

      def log_slow_query
        Gitlab::GraphqlLogger.warn(
          base_log_data.merge(
            message: 'GLQL slow query detected - Duo optimization needed',
            duration_s: duration_s
          )
        )
      end
    end
  end
end
