# frozen_string_literal: true

module Gitlab
  module Metrics
    # Rack middleware for tracking Redis metrics from Grape and Web requests.
    class RedisRackMiddleware
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
        query_time = Gitlab::Instrumentation::Redis.query_time
        request_count = Gitlab::Instrumentation::Redis.get_request_count

        transaction.increment(:http_redis_requests_total, request_count) do
          docstring 'Amount of calls to Redis servers during web requests'
        end

        transaction.observe(:http_redis_requests_duration_seconds, query_time) do
          docstring 'Query time for Redis servers during web requests'
          buckets Gitlab::Instrumentation::Redis::QUERY_TIME_BUCKETS
        end
      end
    end
  end
end
