# frozen_string_literal: true

# Interface to the Redis-backed cache store for keys that use a Redis set
# This is a copy of Gitlab::RepositorySetCache that will be extended with
# rebuild queue functionality for incremental ref cache updates.
module Gitlab
  module Repositories
    class RebuildableSetCache < Gitlab::SetCache
      # TTL for pending events queue during cache rebuilds.
      # This value is arbitrary and can be adjusted based on observed behavior.
      PENDING_EVENT_TTL = 1.hour

      # TTL for rebuild lock flag (prevents stuck rebuilds).
      # This value is arbitrary and can be adjusted based on observed behavior.
      REBUILD_FLAG_TTL = 10.minutes

      # TTL for trust flag (cache self-heals when expired).
      # This value is arbitrary and can be adjusted based on observed behavior.
      TRUST_TTL = 1.hour

      # Value used for Redis flag keys (trust, rebuild)
      FLAG_VALUE = '1'

      # Cache key suffixes for different status types
      CACHE_KEYS_STATUSES = {
        pending: 'pending',
        rebuild: 'rebuild',
        trusted: 'trusted'
      }.freeze

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

      def pending_key(type)
        suffixed_cache_key(type, CACHE_KEYS_STATUSES[:pending])
      end

      def rebuild_flag_key(type)
        suffixed_cache_key(type, CACHE_KEYS_STATUSES[:rebuild])
      end

      def trust_key(type)
        suffixed_cache_key(type, CACHE_KEYS_STATUSES[:trusted])
      end

      def trusted?(key)
        exists_in_redis?(trust_key(key))
      end

      def rebuilding?(key)
        exists_in_redis?(rebuild_flag_key(key))
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

      def fetch(key)
        full_key = cache_key(key)

        smembers, exists = with do |redis|
          redis.multi do |multi|
            multi.smembers(full_key)
            multi.exists?(full_key) # rubocop:disable CodeReuse/ActiveRecord -- Not ActiveRecord
          end
        end

        return smembers if exists

        log_cache_operation(key)

        write(key, yield)
      end

      # Searches the cache set using SSCAN with the MATCH option. The MATCH
      # parameter is the pattern argument.
      # See https://redis.io/commands/scan#the-match-option for more information.
      # Returns an Enumerator that enumerates all SSCAN hits.
      def search(key, pattern)
        full_key = cache_key(key)

        with do |redis|
          exists = redis.exists?(full_key) # rubocop:disable CodeReuse/ActiveRecord -- Not ActiveRecord
          write(key, yield) unless exists

          redis.sscan_each(full_key, match: pattern)
        end
      end

      private

      def suffixed_cache_key(type, suffix)
        "#{cache_namespace}:#{type}:#{suffix}:#{namespace}"
      end

      def exists_in_redis?(redis_key)
        with { |redis| redis.exists?(redis_key) } # rubocop:disable CodeReuse/ActiveRecord -- Not ActiveRecord
      rescue ::Redis::BaseError
        false
      end

      def mark_trusted(key)
        with { |redis| redis.set(trust_key(key), FLAG_VALUE, ex: TRUST_TTL) }
      end

      def mark_untrusted(key)
        with { |redis| redis.del(trust_key(key)) }
      end

      def mark_rebuild_in_progress(key)
        with { |redis| redis.set(rebuild_flag_key(key), FLAG_VALUE, ex: REBUILD_FLAG_TTL, nx: true) }
      end

      def mark_rebuild_complete(key)
        with { |redis| redis.del(rebuild_flag_key(key)) }
      end

      def log_cache_operation(key)
        Gitlab::AppLogger.info(
          message: 'RebuildableSetCache cache miss',
          cache_key: key,
          class: self.class.name
        )
      end

      def cache
        Gitlab::Redis::RepositoryCache
      end

      def with(&blk)
        cache.with(&blk) # rubocop:disable CodeReuse/ActiveRecord -- Not ActiveRecord
      end
    end
  end
end
