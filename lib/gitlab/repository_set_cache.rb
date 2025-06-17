# frozen_string_literal: true

# Interface to the Redis-backed cache store for keys that use a Redis set
module Gitlab
  class RepositorySetCache < Gitlab::SetCache
    attr_reader :repository, :namespace, :expires_in

    def initialize(repository, extra_namespace: nil, expires_in: 2.weeks)
      @repository = repository
      @namespace = repository.full_path.to_s
      @namespace += ":#{repository.project.id}" if repository.project
      @namespace = "#{@namespace}:#{extra_namespace}" if extra_namespace
      @expires_in = expires_in
    end

    def cache_key(type)
      super("#{type}:#{namespace}")
    end

    def write(key, value)
      full_key = cache_key(key)

      with do |redis|
        redis.multi do |multi|
          multi.unlink(full_key)

          # Splitting into groups of 1000 prevents us from creating a too-long
          # Redis command
          value.each_slice(1000) { |subset| multi.sadd(full_key, subset) }

          multi.expire(full_key, expires_in)
        end
      end

      value
    end

    def fetch(key, &block)
      full_key = cache_key(key)

      smembers, exists = with do |redis|
        redis.multi do |multi|
          multi.smembers(full_key)
          multi.exists?(full_key) # rubocop:disable CodeReuse/ActiveRecord
        end
      end

      return smembers if exists

      log_cache_operation(key) if Feature.enabled?(:repository_set_cache_logging, repository.project)

      write(key, yield)
    end

    # Searches the cache set using SSCAN with the MATCH option. The MATCH
    # parameter is the pattern argument.
    # See https://redis.io/commands/scan#the-match-option for more information.
    # Returns an Enumerator that enumerates all SSCAN hits.
    def search(key, pattern, &block)
      full_key = cache_key(key)

      with do |redis|
        exists = redis.exists?(full_key) # rubocop:disable CodeReuse/ActiveRecord
        write(key, yield) unless exists

        redis.sscan_each(full_key, match: pattern)
      end
    end

    private

    def log_cache_operation(key)
      Gitlab::AppLogger.info(
        message: 'RepositorySetCache cache miss',
        cache_key: key,
        class: self.class.name
      )
    end

    def cache
      Gitlab::Redis::RepositoryCache
    end

    def with(&blk)
      cache.with(&blk) # rubocop:disable CodeReuse/ActiveRecord
    end
  end
end
