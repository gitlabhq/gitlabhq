# frozen_string_literal: true

module Gitlab
  module Metrics
    module Exporter
      class MetricsMiddleware
        def initialize(app, pid)
          @app = app
          default_labels = {
            pid: pid
          }
          @requests_total = ::Gitlab::Metrics.counter(
            :exporter_http_requests_total, 'Total number of HTTP requests', default_labels
          )
          @request_durations = ::Gitlab::Metrics.histogram(
            :exporter_http_request_duration_seconds,
            'HTTP request duration histogram (seconds)',
            default_labels,
            [0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10]
          )
        end

        def call(env)
          start = ::Gitlab::Metrics::System.monotonic_time
          @app.call(env).tap do |response|
            duration = ::Gitlab::Metrics::System.monotonic_time - start

            labels = {
              method: env['REQUEST_METHOD'].downcase,
              path: env['PATH_INFO'].to_s,
              code: response.first.to_s
            }

            @requests_total.increment(labels)
            @request_durations.observe(labels, duration)
          end
        end
      end
    end
  end
end
