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
      DRAIN_BATCH_SIZE = 1000

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
        @namespace += ":{#{repository.project.id}}" if repository.project
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
          log_event(:dual_write, key, ref: ref_name, deleted: deleted)
          dual_write(key, ref_name, deleted)
        else
          log_event(:simple_update, key, ref: ref_name, deleted: deleted)
          simple_update(key, ref_name, deleted)
        end
      end

      # Rebuild cache with queue drain mechanism
      # @param key [String] Cache key
      # @param value [Array<String>] Canonical values from source (e.g., Gitaly)
      # @return [Array<String>] Final cache contents after reconciliation
      def write(key, value)
        full_key = cache_key(key)

        # 1. Acquire rebuild lock (prevents concurrent rebuilds)
        unless mark_rebuild_in_progress(key)
          log_event(:rebuild_skipped, key, reason: 'another rebuild in progress')
          return value
        end

        begin
          with do |redis|
            log_event(:rebuild_started, key, canonical_count: value.size)

            # 2. Pre-drain: collect pending events before overwrite
            pre_drain_additions, pre_drain_deletions = drain_pending_events(key)

            if pre_drain_additions.any? || pre_drain_deletions.any?
              log_event(:pre_drain_completed, key,
                additions: pre_drain_additions.size,
                deletions: pre_drain_deletions.size)
            end

            # 3. Build final set: canonical + pending events
            final_set = Set.new(value)
            final_set.merge(pre_drain_additions)
            final_set.subtract(pre_drain_deletions)

            # 4. Atomic cache overwrite
            redis.multi do |multi|
              multi.unlink(full_key)

              # Splitting into groups of 1000 prevents us from creating a too-long
              # Redis command
              final_set.each_slice(DRAIN_BATCH_SIZE) { |subset| multi.sadd(full_key, subset) }

              multi.expire(full_key, expires_in)
            end

            # 5. Post-drain: repair events that arrived during overwrite
            post_drain_additions, post_drain_deletions = drain_pending_events(key)

            if post_drain_additions.any? || post_drain_deletions.any?
              log_event(:post_drain_completed, key,
                additions: post_drain_additions.size,
                deletions: post_drain_deletions.size)
              apply_pending_events(key, post_drain_additions, post_drain_deletions)
            end

            # 6. Mark cache as trusted
            mark_trusted(key)

            # Return final contents
            final_set.merge(post_drain_additions)
            final_set.subtract(post_drain_deletions)

            log_event(:rebuild_completed, key, final_count: final_set.size)

            final_set.to_a
          end
        ensure
          # 7. Release rebuild lock
          mark_rebuild_complete(key)
        end
      rescue ::Redis::BaseError => e
        log_event(:rebuild_failed, key, level: :error,
          error_class: e.class.name,
          error_message: e.message)
        mark_untrusted(key)
        raise
      end

      def fetch(key)
        full_key = cache_key(key)

        smembers, exists, is_trusted = with do |redis|
          redis.multi do |multi|
            multi.smembers(full_key)
            multi.exists?(full_key) # rubocop:disable CodeReuse/ActiveRecord -- Not ActiveRecord
            multi.exists?(trust_key(key)) # rubocop:disable CodeReuse/ActiveRecord -- Not ActiveRecord
          end
        end

        if exists && is_trusted
          log_event(:cache_hit, key, count: smembers.size)
          return smembers
        end

        log_event(:cache_miss, key, exists: exists, trusted: is_trusted)

        write(key, yield)
      end

      # Searches the cache set using SSCAN with the MATCH option. The MATCH
      # parameter is the pattern argument.
      # See https://redis.io/commands/scan#the-match-option for more information.
      # Returns an Enumerator that enumerates all SSCAN hits.
      def search(key, pattern)
        full_key = cache_key(key)

        with do |redis|
          exists, is_trusted = redis.pipelined do |pipeline|
            pipeline.exists?(full_key) # rubocop:disable CodeReuse/ActiveRecord -- Not ActiveRecord
            pipeline.exists?(trust_key(key)) # rubocop:disable CodeReuse/ActiveRecord -- Not ActiveRecord
          end

          write(key, yield) unless exists && is_trusted

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
        log_event(:simple_update_failed, key, level: :error,
          error_class: e.class.name,
          error_message: e.message)
        mark_untrusted(key)
        raise
      end

      # Update cache and enqueue event during rebuild
      # Ensures no events are lost during cache reconstruction
      # @param key [String] Cache key
      # @param ref_name [String] Short ref name (e.g., "main")
      # @param deleted [Boolean] Whether to remove (true) or add (false)
      def dual_write(key, ref_name, deleted)
        full_key = cache_key(key)
        pending = pending_key(key)
        event = encode_event(ref_name, deleted)

        with do |redis|
          # Enqueue event first for rebuild process to reconcile.
          # This ensures no events are lost even if a failure occurs
          # between operations - cache updates self-heal naturally,
          # but lost events cannot be recovered.
          redis.pipelined do |pipeline|
            pipeline.lpush(pending, event)
            pipeline.expire(pending, PENDING_EVENT_TTL)
          end

          if deleted
            redis.eval(SREM_IF_EXISTS_SCRIPT, keys: [full_key], argv: [ref_name])
          else
            redis.eval(SADD_IF_EXISTS_SCRIPT, keys: [full_key], argv: [ref_name])
          end
        end
      rescue ::Redis::BaseError => e
        log_event(:dual_write_failed, key, level: :error,
          error_class: e.class.name,
          error_message: e.message)
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

      # Drain pending queue and return events separated by operation type
      # @param key [String] Cache key
      # @return [Array<Set, Set>] [additions, deletions]
      def drain_pending_events(key)
        pending = pending_key(key)
        additions = Set.new
        deletions = Set.new

        with do |redis|
          loop do
            events = redis.rpop(pending, DRAIN_BATCH_SIZE)
            break if events.blank?

            events.each do |event|
              ref_name, deleted = decode_event(event)
              next if ref_name.nil?

              if deleted
                deletions.add(ref_name)
                additions.delete(ref_name)
              else
                additions.add(ref_name)
                deletions.delete(ref_name)
              end
            end
          end
        end

        [additions, deletions]
      end

      # Apply pending events directly to cache
      # @param key [String] Cache key
      # @param additions [Set<String>] Refs to add
      # @param deletions [Set<String>] Refs to remove
      def apply_pending_events(key, additions, deletions)
        full_key = cache_key(key)

        with do |redis|
          redis.pipelined do |pipeline|
            additions.each_slice(DRAIN_BATCH_SIZE) { |batch| pipeline.sadd(full_key, batch) }
            deletions.each_slice(DRAIN_BATCH_SIZE) { |batch| pipeline.srem(full_key, batch) }
          end
        end
      end

      # Encode event for pending queue
      # @param ref_name [String] Short ref name
      # @param deleted [Boolean] Whether ref was deleted
      # @return [String] Encoded event (e.g., "+main" or "-feature")
      def encode_event(ref_name, deleted)
        "#{deleted ? '-' : '+'}#{ref_name}"
      end

      # Decode event from pending queue
      # @param event [String] Encoded event (e.g., "+main" or "-feature")
      # @return [Array<String, Boolean>] [ref_name, deleted]
      def decode_event(event)
        return [nil, false] if event.blank?

        deleted = event.start_with?('-')
        ref_name = event[1..]

        [ref_name, deleted]
      end

      def mark_trusted(key)
        with { |redis| redis.set(trust_key(key), FLAG_VALUE, ex: TRUST_TTL) }
        log_event(:cache_marked_trusted, key)
      end

      def mark_untrusted(key)
        with { |redis| redis.del(trust_key(key)) }
        log_event(:cache_marked_untrusted, key)
      end

      def mark_rebuild_in_progress(key)
        with { |redis| redis.set(rebuild_flag_key(key), FLAG_VALUE, ex: REBUILD_FLAG_TTL, nx: true) }
      end

      def mark_rebuild_complete(key)
        with { |redis| redis.del(rebuild_flag_key(key)) }
      end

      def log_event(event, key, level: :info, **extra)
        return if level != :error && !Feature.enabled?(:ref_cache_verbose_logging, repository.project)

        payload = {
          message: event.to_s,
          class: self.class.name,
          rebuildable_cache: { **extra, event: event, cache_key: key }
        }

        Gitlab::ApplicationContext.with_context(project: repository.project) do
          log_payload(level, payload)
        end
      end

      def log_payload(level, payload)
        case level
        when :error
          Gitlab::AppLogger.error(payload)
        else
          Gitlab::AppLogger.info(payload)
        end
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
