# frozen_string_literal: true

# Interface to the Redis-backed cache store to keep track of complete cache keys
# for a ReactiveCache resource.
module Gitlab
  class ReactiveCacheSetCache < Gitlab::SetCache
    attr_reader :expires_in

    def initialize(expires_in: 10.minutes)
      @expires_in = expires_in
    end

    # NOTE Remove as part of #331319
    def old_cache_key(key)
      "#{cache_namespace}:#{key}:set"
    end

    def cache_key(key)
      super(key)
    end

    def clear_cache!(key)
      with do |redis|
        keys = read(key).map { |value| "#{cache_namespace}:#{value}" }
        keys << cache_key(key)

        redis.pipelined do
          keys.each_slice(1000) { |subset| redis.unlink(*subset) }
        end
      end
    end
  end
end
