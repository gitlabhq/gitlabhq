# frozen_string_literal: true

module Gitlab
  module Metrics
    class RequestsRackMiddleware
      include Gitlab::Metrics::SliConfig

      puma_enabled!

      HTTP_METHODS = {
        "delete" => %w[200 202 204 303 400 401 403 404 500 503],
        "get" => %w[200 204 301 302 303 304 307 400 401 403 404 410 422 429 500 503],
        "head" => %w[200 204 301 302 303 401 403 404 410 500],
        "options" => %w[200 404],
        "patch" => %w[200 202 204 400 403 404 409 416 500],
        "post" => %w[200 201 202 204 301 302 303 304 400 401 403 404 406 409 410 412 422 429 500 503],
        "put" => %w[200 202 204 400 401 403 404 405 406 409 410 422 500]
      }.freeze

      HEALTH_ENDPOINT = %r{^/-/(liveness|readiness|health|metrics)/?$}

      FEATURE_CATEGORY_DEFAULT = ::Gitlab::FeatureCategories::FEATURE_CATEGORY_DEFAULT
      ENDPOINT_MISSING = 'unknown'

      # These were the top 5 categories at a point in time, chosen as a
      # reasonable default. If we initialize every category we'll end up
      # with an explosion in unused metric combinations, but we want the
      # most common ones to be always present.
      FEATURE_CATEGORIES_TO_INITIALIZE = ['system_access',
                                          'code_review_workflow', 'continuous_integration',
                                          'not_owned', 'source_code_management',
                                          FEATURE_CATEGORY_DEFAULT].freeze

      REQUEST_URGENCY_KEY = 'gitlab.request_urgency'

      def initialize(app)
        @app = app
      end

      def self.http_requests_total
        ::Gitlab::Metrics.counter(:http_requests_total, 'Request count')
      end

      def self.rack_uncaught_errors_count
        ::Gitlab::Metrics.counter(:rack_uncaught_errors_total, 'Request handling uncaught errors count')
      end

      def self.http_request_duration_seconds
        ::Gitlab::Metrics.histogram(:http_request_duration_seconds, 'Request handling execution time',
          {}, [0.05, 0.1, 0.25, 0.5, 0.7, 1, 2.5, 5, 10, 25])
      end

      def self.http_health_requests_total
        ::Gitlab::Metrics.counter(:http_health_requests_total, 'Health endpoint request count')
      end

      def self.initialize_slis!
        # This initialization is done to avoid gaps in scraped metrics after
        # restarts. It makes sure all counters/histograms are available at
        # process start.
        #
        # For example `rate(http_requests_total{status="500"}[1m])` would return
        # no data until the first 500 error would occur.
        HTTP_METHODS.each do |method, statuses|
          http_request_duration_seconds.get({ method: method })

          statuses.product(FEATURE_CATEGORIES_TO_INITIALIZE) do |status, feature_category|
            http_requests_total.get({ method: method, status: status, feature_category: feature_category })
          end
        end

        Gitlab::Metrics::RailsSlis.initialize_request_slis!
      end

      def call(env)
        method = env['REQUEST_METHOD'].downcase
        method = 'INVALID' unless HTTP_METHODS.key?(method)
        started = ::Gitlab::Metrics::System.monotonic_time
        health_endpoint = health_endpoint?(env['PATH_INFO'])
        status = 'undefined'

        begin
          status, headers, body = @app.call(env)
          return [status, headers, body] if health_endpoint

          urgency = urgency_for_env(env)
          if ::Gitlab::Metrics.record_duration_for_status?(status)
            elapsed = ::Gitlab::Metrics::System.monotonic_time - started
            self.class.http_request_duration_seconds.observe({ method: method }, elapsed)
            record_apdex(urgency, elapsed)
          end

          record_error(urgency, status)

          [status, headers, body]
        rescue StandardError
          self.class.rack_uncaught_errors_count.increment
          raise
        ensure
          if health_endpoint
            self.class.http_health_requests_total.increment(status: status.to_s, method: method)
          else
            self.class.http_requests_total.increment(
              status: status.to_s,
              method: method,
              feature_category: feature_category.presence || FEATURE_CATEGORY_DEFAULT
            )
          end
        end
      end

      def health_endpoint?(path)
        return false if path.blank?

        HEALTH_ENDPOINT.match?(CGI.unescape(path))
      end

      def feature_category
        ::Gitlab::ApplicationContext.current_context_attribute(:feature_category)
      end

      def endpoint_id
        ::Gitlab::ApplicationContext.current_context_attribute(:caller_id)
      end

      def record_apdex(urgency, elapsed)
        Gitlab::Metrics::RailsSlis.request_apdex.increment(
          labels: labels_from_context.merge(request_urgency: urgency.name),
          success: elapsed < urgency.duration
        )
      end

      def record_error(urgency, status)
        Gitlab::Metrics::RailsSlis.request_error_rate.increment(
          labels: labels_from_context.merge(request_urgency: urgency.name),
          error: ::Gitlab::Metrics.server_error?(status)
        )
      end

      def labels_from_context
        {
          feature_category: feature_category.presence || FEATURE_CATEGORY_DEFAULT,
          endpoint_id: endpoint_id.presence || ENDPOINT_MISSING
        }
      end

      def urgency_for_env(env)
        endpoint_urgency =
          if env[REQUEST_URGENCY_KEY].present?
            env[REQUEST_URGENCY_KEY]
          elsif env['api.endpoint'].present?
            env['api.endpoint'].options[:for].try(:urgency_for_app, env['api.endpoint'])
          elsif env['action_controller.instance'].present? && env['action_controller.instance'].respond_to?(:urgency)
            env['action_controller.instance'].urgency
          end

        endpoint_urgency || Gitlab::EndpointAttributes::DEFAULT_URGENCY
      end
    end
  end
end
