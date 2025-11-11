# frozen_string_literal: true

module Integrations
  module Glql
    # Service for handling GLQL queries with rate limiting, complexity tracking, and logging
    # Used by both Glql::BaseController and API::Glql
    class QueryService
      include Gitlab::Utils::StrongMemoize

      GlqlQueryLockedError = Class.new(StandardError)

      def initialize(current_user:, original_query:, request: nil, current_organization: nil)
        @current_user = current_user
        @original_query = original_query
        @request = request
        @current_organization = current_organization
      end

      def execute(query:, variables: {}, context: {})
        @query = query
        @variables = variables
        @graphql_context = build_graphql_context(context)

        start_time = Gitlab::Metrics::System.monotonic_time
        exception_caught = nil

        begin
          check_rate_limit
          result = execute_graphql

          # Enhance GraphQL logs with GLQL metadata for both controller and API
          enhance_graphql_logs

          {
            data: result&.dig('data'),
            errors: result&.dig('errors'),
            complexity_score: extract_complexity_score,
            duration_s: Gitlab::Metrics::System.monotonic_time - start_time,
            timeout_occurred: false,
            rate_limited: false
          }

        rescue GlqlQueryLockedError => e
          exception_caught = e
          # Enhance logs even for rate limited queries
          enhance_graphql_logs

          {
            data: nil,
            errors: [{ message: e.message }],
            complexity_score: nil,
            duration_s: Gitlab::Metrics::System.monotonic_time - start_time,
            timeout_occurred: false,
            rate_limited: true
          }

        rescue ActiveRecord::QueryAborted => e
          exception_caught = e
          # Handle timeout - increment rate limiter
          increment_rate_limit_counter

          # Enhance logs for timeout scenarios
          enhance_graphql_logs

          {
            data: nil,
            errors: [{ message: 'Query timed out' }],
            complexity_score: extract_complexity_score,
            duration_s: Gitlab::Metrics::System.monotonic_time - start_time,
            timeout_occurred: true,
            rate_limited: false
          }

        rescue StandardError => e
          exception_caught = e
          # Handle other errors
          enhance_graphql_logs

          {
            data: nil,
            errors: [{ message: e.message }],
            complexity_score: extract_complexity_score,
            duration_s: Gitlab::Metrics::System.monotonic_time - start_time,
            timeout_occurred: false,
            rate_limited: false,
            exception: e
          }

        ensure
          # Record SLI metrics
          increment_glql_sli(
            duration_s: Gitlab::Metrics::System.monotonic_time - start_time,
            error_type: error_type_from(exception_caught)
          )
        end
      end

      private

      attr_reader :current_user, :original_query, :request, :current_organization, :query, :variables,
        :graphql_context

      def check_rate_limit
        return unless Gitlab::ApplicationRateLimiter.peek(:glql, scope: query_sha)

        raise GlqlQueryLockedError,
          'Query temporarily blocked due to repeated timeouts. Please try again later or narrow your search scope.'
      end

      def execute_graphql
        ::Gitlab::Database::LoadBalancing::SessionMap.use_replica_if_available do
          GitlabSchema.execute(query, variables: variables, context: graphql_context)
        end
      end

      def build_graphql_context(additional_context = {})
        base_context = {
          current_user: current_user,
          is_sessionless_user: true,
          current_organization: current_organization,
          request: request
        }

        base_context.merge(additional_context)
      end

      def extract_complexity_score
        graphql_logs = RequestStore.store[:graphql_logs]
        return unless graphql_logs&.any?

        graphql_logs.last&.dig(:complexity)
      end

      def enhance_graphql_logs
        # Add GLQL-specific metadata to GraphQL logs
        # This ensures both controller and API have consistent log format
        graphql_logs = RequestStore.store[:graphql_logs]
        return unless graphql_logs&.any?

        RequestStore.store[:graphql_logs] = graphql_logs.map do |log|
          log.merge(
            glql_referer: request&.headers&.[]("Referer"),
            glql_query_sha: query_sha
          )
        end
      end

      def query_sha
        @query_sha ||= Digest::SHA256.hexdigest(original_query)
      end

      strong_memoize_attr :query_sha

      def increment_rate_limit_counter
        Gitlab::ApplicationRateLimiter.throttled?(:glql, scope: query_sha)
      end

      def increment_glql_sli(duration_s:, error_type:)
        query_urgency = Gitlab::EndpointAttributes::Config::REQUEST_URGENCIES.fetch(:low)

        labels = {
          endpoint_id: caller_endpoint_id,
          feature_category: 'shared',
          query_urgency: query_urgency.name
        }

        Gitlab::Metrics::GlqlSlis.record_error(
          labels: labels.merge(error_type: error_type),
          error: error_type.present?
        )

        return if error_type

        Gitlab::Metrics::GlqlSlis.record_apdex(
          labels: labels.merge(error_type: nil),
          success: duration_s <= query_urgency.duration
        )
      end

      def caller_endpoint_id
        # Try to get from ApplicationContext, fallback to generic
        ::Gitlab::ApplicationContext.current_context_attribute(:caller_id) || 'Glql::QueryService'
      end

      def error_type_from(exception)
        return unless exception

        case exception
        when ActiveRecord::QueryAborted
          :query_aborted
        when GlqlQueryLockedError
          nil # Rate limited queries are not considered errors for SLI
        else
          :other
        end
      end
    end
  end
end
