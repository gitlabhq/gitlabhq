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

      FEATURE_CATEGORY_HEADER = 'X-Gitlab-Feature-Category'
      FEATURE_CATEGORY_DEFAULT = 'unknown'

      def initialize(app)
        @app = app
      end

      def self.http_request_total
        @http_request_total ||= ::Gitlab::Metrics.counter(:http_requests_total, 'Request count')
      end

      def self.rack_uncaught_errors_count
        @rack_uncaught_errors_count ||= ::Gitlab::Metrics.counter(:rack_uncaught_errors_total, 'Request handling uncaught errors count')
      end

      def self.http_request_duration_seconds
        @http_request_duration_seconds ||= ::Gitlab::Metrics.histogram(:http_request_duration_seconds, 'Request handling execution time',
                                                           {}, [0.05, 0.1, 0.25, 0.5, 0.7, 1, 2.5, 5, 10, 25])
      end

      def self.http_health_requests_total
        @http_health_requests_total ||= ::Gitlab::Metrics.counter(:http_health_requests_total, 'Health endpoint request count')
      end

      def self.initialize_http_request_duration_seconds
        HTTP_METHODS.each do |method, statuses|
          statuses.each do |status|
            http_request_duration_seconds.get({ method: method, status: status.to_s })
          end
        end
      end

      def call(env)
        method = env['REQUEST_METHOD'].downcase
        method = 'INVALID' unless HTTP_METHODS.key?(method)
        started = Time.now.to_f
        health_endpoint = health_endpoint?(env['PATH_INFO'])
        status = 'undefined'
        feature_category = nil

        begin
          status, headers, body = @app.call(env)

          elapsed = Time.now.to_f - started
          feature_category = headers&.fetch(FEATURE_CATEGORY_HEADER, nil)

          unless health_endpoint
            RequestsRackMiddleware.http_request_duration_seconds.observe({ method: method, status: status.to_s }, elapsed)
          end

          [status, headers, body]
        rescue
          RequestsRackMiddleware.rack_uncaught_errors_count.increment
          raise
        ensure
          if health_endpoint
            RequestsRackMiddleware.http_health_requests_total.increment(status: status, method: method)
          else
            RequestsRackMiddleware.http_request_total.increment(status: status, method: method, feature_category: feature_category || FEATURE_CATEGORY_DEFAULT)
          end
        end
      end

      def health_endpoint?(path)
        return false if path.blank?

        HEALTH_ENDPOINT.match?(CGI.unescape(path))
      end
    end
  end
end
