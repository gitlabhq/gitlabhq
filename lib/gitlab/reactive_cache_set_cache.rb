# frozen_string_literal: true

# Interface to the Redis-backed cache store to keep track of complete cache keys
# for a ReactiveCache resource.
module Gitlab
  class ReactiveCacheSetCache < Gitlab::SetCache
    attr_reader :expires_in

    def initialize(expires_in: 10.minutes)
      @expires_in = expires_in
    end

    def cache_key(key)
      "#{cache_type}:#{key}:set"
    end

    def clear_cache!(key)
      with do |redis|
        keys = read(key).map { |value| "#{cache_type}:#{value}" }
        keys << cache_key(key)

        redis.pipelined do
          keys.each_slice(1000) { |subset| redis.unlink(*subset) }
        end
      end
    end

    private

    def cache_type
      Gitlab::Redis::Cache::CACHE_NAMESPACE
    end
  end
end
