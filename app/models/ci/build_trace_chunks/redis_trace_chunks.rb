# frozen_string_literal: true

module Ci
  module BuildTraceChunks
    class RedisTraceChunks < RedisBase
      private

      def with_redis
        Gitlab::Redis::TraceChunks.with { |redis| yield(redis) }
      end
    end
  end
end
