# frozen_string_literal: true

module Gitlab
  module Metrics
    class RequestsRackMiddleware
      HTTP_METHODS = {
        "delete" => %w(200 202 204 303 400 401 403 404 500 503),
        "get" => %w(200 204 301 302 303 304 307 400 401 403 404 410 422 429 500 503),
        "head" => %w(200 204 301 302 303 401 403 404 410 500),
        "options" => %w(200 404),
        "patch" => %w(200 202 204 400 403 404 409 416 500),
        "post" => %w(200 201 202 204 301 302 303 304 400 401 403 404 406 409 410 412 422 429 500 503),
        "put" => %w(200 202 204 400 401 403 404 405 406 409 410 422 500)
      }.freeze

      HEALTH_ENDPOINT = /^\/-\/(liveness|readiness|health|metrics)\/?$/.freeze

      FEATURE_CATEGORY_DEFAULT = 'unknown'

      # These were the top 5 categories at a point in time, chosen as a
      # reasonable default. If we initialize every category we'll end up
      # with an explosion in unused metric combinations, but we want the
      # most common ones to be always present.
      FEATURE_CATEGORIES_TO_INITIALIZE = ['authentication_and_authorization',
                                          'code_review', 'continuous_integration',
                                          'not_owned', 'source_code_management',
                                          FEATURE_CATEGORY_DEFAULT].freeze

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

      def self.initialize_metrics
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
      end

      def call(env)
        method = env['REQUEST_METHOD'].downcase
        method = 'INVALID' unless HTTP_METHODS.key?(method)
        started = Gitlab::Metrics::System.monotonic_time
        health_endpoint = health_endpoint?(env['PATH_INFO'])
        status = 'undefined'

        begin
          status, headers, body = @app.call(env)

          elapsed = Gitlab::Metrics::System.monotonic_time - started

          if !health_endpoint && Gitlab::Metrics.record_duration_for_status?(status)
            RequestsRackMiddleware.http_request_duration_seconds.observe({ method: method }, elapsed)
          end

          [status, headers, body]
        rescue StandardError
          RequestsRackMiddleware.rack_uncaught_errors_count.increment
          raise
        ensure
          if health_endpoint
            RequestsRackMiddleware.http_health_requests_total.increment(status: status.to_s, method: method)
          else
            RequestsRackMiddleware.http_requests_total.increment(
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
    end
  end
end
