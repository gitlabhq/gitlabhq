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

      # Lua script for atomic SADD only if key exists.
      # Prevents race condition where key expires between EXISTS check and SADD,
      # which would create a partial cache with only one element.
      SADD_IF_EXISTS_SCRIPT = <<~LUA
        if redis.call('EXISTS', KEYS[1]) == 1 then
          return redis.call('SADD', KEYS[1], ARGV[1])
        end
        return 0
      LUA

      # Lua script for atomic SREM only if key exists.
      # Prevents race condition where key expires between EXISTS check and SREM.
      SREM_IF_EXISTS_SCRIPT = <<~LUA
        if redis.call('EXISTS', KEYS[1]) == 1 then
          return redis.call('SREM', KEYS[1], ARGV[1])
        end
        return 0
      LUA

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

      # Handle individual ref changes (add or remove)
      # This is the entry point for incremental cache updates.
      # @param key [String] Cache key (e.g., 'branch_names', 'tag_names')
      # @param ref [String] Full ref path (e.g., "refs/heads/main")
      # @param deleted [Boolean] Whether the ref was deleted
      def handle_ref_change(key, ref, deleted)
        ref_name = Gitlab::Git.ref_name(ref)

        if rebuilding?(key)
          # TODO: Implement dual_write in next MR
          nil
        else
          simple_update(key, ref_name, deleted)
        end
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

        mark_trusted(key)

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

      # Update cache by adding or removing a single ref (no rebuild in progress)
      # Uses Lua scripts to ensure atomic check-and-update operations.
      # @param key [String] Cache key
      # @param ref_name [String] Short ref name (e.g., "main")
      # @param deleted [Boolean] Whether to remove (true) or add (false)
      def simple_update(key, ref_name, deleted)
        full_key = cache_key(key)

        with do |redis|
          if deleted
            redis.eval(SREM_IF_EXISTS_SCRIPT, keys: [full_key], argv: [ref_name])
          else
            redis.eval(SADD_IF_EXISTS_SCRIPT, keys: [full_key], argv: [ref_name])
          end
        end
      rescue ::Redis::BaseError => e
        log_error(:simple_update_failed, key, e)
        mark_untrusted(key)
        raise
      end

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

      def log_error(event, key, error)
        Gitlab::AppLogger.error(
          message: 'RebuildableSetCache error',
          event: event,
          cache_key: key,
          error_class: error.class.name,
          error_message: error.message,
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
