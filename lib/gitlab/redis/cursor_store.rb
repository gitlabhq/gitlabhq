# frozen_string_literal: true

module Gitlab
  module Redis
    class CursorStore
      def initialize(cache_key, ttl: 1.hour)
        @cache_key = cache_key
        @ttl = ttl.to_i
      end

      def commit(payload)
        Gitlab::Redis::SharedState.with do |redis|
          redis.hset(cache_key, payload, ex: ttl)
        end
      end

      def cursor
        Gitlab::Redis::SharedState.with do |redis|
          redis.hgetall(cache_key)
        end.except('ex')
      end

      private

      attr_reader :cache_key, :ttl
    end
  end
end
