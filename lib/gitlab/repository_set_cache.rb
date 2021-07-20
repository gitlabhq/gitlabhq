# frozen_string_literal: true

# Interface to the Redis-backed cache store for keys that use a Redis set
module Gitlab
  class RepositorySetCache < Gitlab::SetCache
    attr_reader :repository, :namespace, :expires_in

    def initialize(repository, extra_namespace: nil, expires_in: 2.weeks)
      @repository = repository
      @namespace = "#{repository.full_path}"
      @namespace += ":#{repository.project.id}" if repository.project
      @namespace = "#{@namespace}:#{extra_namespace}" if extra_namespace
      @expires_in = expires_in
    end

    # NOTE Remove as part of #331319
    def old_cache_key(type)
      "#{type}:#{namespace}:set"
    end

    def cache_key(type)
      super("#{type}:#{namespace}")
    end

    def write(key, value)
      full_key = cache_key(key)

      with do |redis|
        redis.multi do
          redis.unlink(full_key)

          # Splitting into groups of 1000 prevents us from creating a too-long
          # Redis command
          value.each_slice(1000) { |subset| redis.sadd(full_key, subset) }

          redis.expire(full_key, expires_in)
        end
      end

      value
    end

    def fetch(key, &block)
      full_key = cache_key(key)

      smembers, exists = with do |redis|
        redis.multi do
          redis.smembers(full_key)
          redis.exists(full_key)
        end
      end

      return smembers if exists

      write(key, yield)
    end

    # Searches the cache set using SSCAN with the MATCH option. The MATCH
    # parameter is the pattern argument.
    # See https://redis.io/commands/scan#the-match-option for more information.
    # Returns an Enumerator that enumerates all SSCAN hits.
    def search(key, pattern, &block)
      full_key = cache_key(key)

      with do |redis|
        exists = redis.exists(full_key)
        write(key, yield) unless exists

        redis.sscan_each(full_key, match: pattern)
      end
    end
  end
end
