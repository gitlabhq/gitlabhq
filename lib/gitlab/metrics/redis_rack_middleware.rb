# frozen_string_literal: true

module Gitlab
  module Metrics
    # Rack middleware for tracking Redis metrics from Grape and Web requests.
    class RedisRackMiddleware
      def initialize(app)
        @app = app

        @requests_total_counter = Gitlab::Metrics.counter(:http_redis_requests_total,
                                                          'Amount of calls to Redis servers during web requests',
                                                          Gitlab::Metrics::Transaction::BASE_LABELS)
        @requests_duration_histogram = Gitlab::Metrics.histogram(:http_redis_requests_duration_seconds,
                                                                 'Query time for Redis servers during web requests',
                                                                 Gitlab::Metrics::Transaction::BASE_LABELS,
                                                                 Gitlab::Instrumentation::Redis::QUERY_TIME_BUCKETS)
      end

      def call(env)
        transaction = Gitlab::Metrics.current_transaction

        @app.call(env)
      ensure
        record_metrics(transaction)
      end

      private

      def record_metrics(transaction)
        labels = transaction.labels
        query_time = Gitlab::Instrumentation::Redis.query_time
        request_count = Gitlab::Instrumentation::Redis.get_request_count

        @requests_total_counter.increment(labels, request_count)
        @requests_duration_histogram.observe(labels, query_time)
      end
    end
  end
end
