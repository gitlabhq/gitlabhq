# frozen_string_literal: true

# Interface to the Redis-backed cache store for keys that use a Redis set
module Gitlab
  class RepositorySetCache
    attr_reader :repository, :namespace, :expires_in

    def initialize(repository, extra_namespace: nil, expires_in: 2.weeks)
      @repository = repository
      @namespace = "#{repository.full_path}:#{repository.project.id}"
      @namespace = "#{@namespace}:#{extra_namespace}" if extra_namespace
      @expires_in = expires_in
    end

    def cache_key(type)
      "#{type}:#{namespace}:set"
    end

    def expire(key)
      with { |redis| redis.del(cache_key(key)) }
    end

    def exist?(key)
      with { |redis| redis.exists(cache_key(key)) }
    end

    def read(key)
      with { |redis| redis.smembers(cache_key(key)) }
    end

    def write(key, value)
      full_key = cache_key(key)

      with do |redis|
        redis.multi do
          redis.del(full_key)

          # Splitting into groups of 1000 prevents us from creating a too-long
          # Redis command
          value.each_slice(1000) { |subset| redis.sadd(full_key, subset) }

          redis.expire(full_key, expires_in)
        end
      end

      value
    end

    def fetch(key, &block)
      if exist?(key)
        read(key)
      else
        write(key, yield)
      end
    end

    def include?(key, value)
      with { |redis| redis.sismember(cache_key(key), value) }
    end

    private

    def with(&blk)
      Gitlab::Redis::Cache.with(&blk) # rubocop:disable CodeReuse/ActiveRecord
    end
  end
end
