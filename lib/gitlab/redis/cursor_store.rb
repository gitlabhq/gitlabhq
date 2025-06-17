# frozen_string_literal: true

module Gitlab
  module Redis
    class CursorStore
      def initialize(namespace, ttl: 1.hour)
        @namespace = namespace
        @ttl = ttl.to_i
      end

      def commit(payload)
        Gitlab::Redis::SharedState.with do |redis|
          redis.set(cache_key, payload.to_json, ex: ttl)
        end
      end

      def cursor
        Gitlab::Json.parse(value_on_redis).to_h
      end

      private

      attr_reader :namespace, :ttl

      def cache_key
        "CursorStore:#{namespace}"
      end

      def value_on_redis
        Gitlab::Redis::SharedState.with do |redis|
          redis.get(cache_key)
        end
      end
    end
  end
end
