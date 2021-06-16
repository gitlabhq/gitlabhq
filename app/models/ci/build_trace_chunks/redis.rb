# frozen_string_literal: true

module Ci
  module BuildTraceChunks
    class Redis < RedisBase
      private

      def with_redis
        Gitlab::Redis::SharedState.with { |redis| yield(redis) }
      end
    end
  end
end
