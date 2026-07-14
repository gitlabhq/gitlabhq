# frozen_string_literal: true

module Gitlab
  module Metrics
    # Rack middleware for tracking Zoekt metrics from Grape and Web requests.
    class ZoektRackMiddleware
      HISTOGRAM_BUCKETS = [0.1, 0.5, 1, 2, 3, 6, 10, 15, 20, 30, 50].freeze

      def initialize(app)
        @app = app
      end

      def call(env)
        transaction = Gitlab::Metrics.current_transaction

        @app.call(env)
      ensure
        record_metrics(transaction)
      end

      private

      def record_metrics(transaction)
        query_time = ::Gitlab::Instrumentation::Zoekt.query_time
        request_count = ::Gitlab::Instrumentation::Zoekt.get_request_count

        return unless request_count > 0

        transaction.increment(:http_zoekt_requests_total, request_count) do
          docstring 'Amount of calls to Zoekt servers during web requests'
        end

        transaction.observe(:http_zoekt_requests_duration_seconds, query_time) do
          docstring 'Query time for Zoekt servers during web requests'
          buckets HISTOGRAM_BUCKETS
        end
      end
    end
  end
end
