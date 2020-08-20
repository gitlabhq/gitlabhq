# frozen_string_literal: true

module Gitlab
  module Metrics
    # Rack middleware for tracking Elasticsearch metrics from Grape and Web requests.
    class ElasticsearchRackMiddleware
      HISTOGRAM_BUCKETS = [0.1, 0.5, 1, 10, 50].freeze

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
        query_time = ::Gitlab::Instrumentation::ElasticsearchTransport.query_time
        request_count = ::Gitlab::Instrumentation::ElasticsearchTransport.get_request_count

        return unless request_count > 0

        transaction.increment(:http_elasticsearch_requests_total, request_count) do
          docstring 'Amount of calls to Elasticsearch servers during web requests'
        end

        transaction.observe(:http_elasticsearch_requests_duration_seconds, query_time) do
          docstring 'Query time for Elasticsearch servers during web requests'
          buckets HISTOGRAM_BUCKETS
        end
      end
    end
  end
end
