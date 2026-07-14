# frozen_string_literal: true

# Interface to the Redis-backed cache store for keys that use a Redis set
# This is a copy of Gitlab::RepositorySetCache that will be extended with
# rebuild queue functionality for incremental ref cache updates.
module Gitlab
  module Repositories
    class RebuildableSetCache < Gitlab::SetCache
      # TTL for rebuild lock flag (prevents stuck rebuilds).
      # This value is arbitrary and can be adjusted based on observed behavior.
      REBUILD_FLAG_TTL = 10.minutes

      # TTL for pending events queue during cache rebuilds.
      # Matches REBUILD_FLAG_TTL so orphaned events expire before the next rebuild.
      PENDING_EVENT_TTL = REBUILD_FLAG_TTL

      # TTL for trust flag (cache self-heals when expired).
      # This value is arbitrary and can be adjusted based on observed behavior.
      TRUST_TTL = 1.hour
      DRAIN_BATCH_SIZE = 1000

      # Value used for Redis flag keys (trust, rebuild)
      FLAG_VALUE = '1'

      MISSING_PROJECT_ERROR =
        'RebuildableSetCache requires a repository with a project ' \
          '(needed for the {project.id} Redis Cluster hash tag)'

      # Cache keys actually backed by this set cache. #expire is called with the
      # full list of repository methods being invalidated (e.g. branch_count,
      # has_visible_content?), but only these have set/trust keys here, so only
      # these are worth logging.
      SET_BACKED_KEYS = %w[branch_names tag_names].freeze

      # Cache key suffixes for different status types
      CACHE_KEYS_STATUSES = {
        pending: 'pending',
        rebuild: 'rebuild',
        trusted: 'trusted'
      }.freeze

      # Lua script for atomic SADD only if key exists.
      # Prevents race condition where key expires between EXISTS check and SADD,
      # which would create a partial cache with only one element.
      #
      # Returns:
      #   -1: key does not exist (SADD was not attempted)
      #    0: key exists, element was already a member (no-op)
      #    1: key exists, element was added
      SADD_IF_EXISTS_SCRIPT = <<~LUA
        if redis.call('EXISTS', KEYS[1]) == 1 then
          return redis.call('SADD', KEYS[1], ARGV[1])
        end
        return -1
      LUA

      # Lua script for atomic SREM only if key exists.
      # Prevents race condition where key expires between EXISTS check and SREM.
      #
      # Returns:
      #   -1: key does not exist (SREM was not attempted)
      #    0: key exists, element was not a member (no-op)
      #    1: key exists, element was removed
      SREM_IF_EXISTS_SCRIPT = <<~LUA
        if redis.call('EXISTS', KEYS[1]) == 1 then
          return redis.call('SREM', KEYS[1], ARGV[1])
        end
        return -1
      LUA

      # Sets the trust flag (KEYS[2]) only if the set (KEYS[1]) still exists, so a
      # concurrent UNLINK cannot strand a trusted-but-empty cache. ARGV[1] = trust
      # TTL (seconds), ARGV[2] = flag value. Same-slot via the {project.id} hash
      # tag. Returns 1 if trust was granted, 0 if the set was absent.
      TRUST_IF_EXISTS_SCRIPT = <<~LUA
        if redis.call('EXISTS', KEYS[1]) == 1 then
          redis.call('SET', KEYS[2], ARGV[2], 'EX', tonumber(ARGV[1]))
          return 1
        end
        return 0
      LUA

      # Atomically deletes the trust flag (KEYS[2]) and UNLINKs the set (KEYS[1])
      # so a concurrent rebuild cannot grant trust between the two, which would
      # strand a trusted-but-empty cache. Leaves pending_key/rebuild_flag_key for
      # an in-flight #write. Same-slot via the {project.id} hash tag. Returns the
      # number of set keys deleted (0 or 1), matching #expire's contract.
      EXPIRE_KEY_SCRIPT = <<~LUA
        redis.call('DEL', KEYS[2])
        return redis.call('UNLINK', KEYS[1])
      LUA

      attr_reader :repository, :namespace, :expires_in

      def initialize(repository, extra_namespace: nil, expires_in: 2.weeks)
        # The multi-key EVALs (expire, grant trust) require the set and trust keys to
        # share a Redis Cluster slot, which the {project.id} hash tag guarantees. A
        # project-less repository has no hash tag, so its keys diverge and raise
        # CROSSSLOT; such repositories must use Gitlab::RepositorySetCache instead.
        raise ArgumentError, MISSING_PROJECT_ERROR unless repository.project

        @repository = repository
        @namespace = "#{repository.full_path}:{#{repository.project.id}}"
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

      # Expires each key. SET_BACKED_KEYS (branch_names/tag_names) carry a trust
      # flag, so they are expired atomically (set + trust in one eval) to avoid
      # stranding a trusted-but-empty cache that #fetch would serve as a 0-count
      # cache_hit; see EXPIRE_KEY_SCRIPT for why super cannot be reused. All other
      # keys are plain sets with no trust flag, so they fall through to the parent's
      # UNLINK (which also handles Redis Cluster batching).
      def expire(*keys)
        return 0 if keys.empty?

        set_backed, other = keys.partition { |key| SET_BACKED_KEYS.include?(key.to_s) }

        deleted = expire_with_trust(set_backed) + super(*other)

        set_backed.each do |key|
          log_event(:cache_marked_untrusted, key)
          log_event(:cache_expired, key)
        end

        deleted
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
          # Re-check under the lock: another request may have rebuilt and released
          # the lock just before we acquired it. (The redundant Gitaly call still
          # happens upstream in #fetch; only the duplicate overwrite is avoided.)
          smembers, exists, is_trusted = read_with_trust(key)

          if exists && is_trusted
            log_event(:rebuild_skipped, key, reason: 'cache already rebuilt')
            # Return the trusted set, not our value: the winner reconciled it with
            # the pending-event queue, so it is authoritative (like a cache_hit).
            return smembers
          end

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

            # Reconcile before deciding trust so final_set.empty? matches Redis.
            final_set.merge(post_drain_additions)
            final_set.subtract(post_drain_deletions)

            # 6. Grant trust
            grant_trust(key, final_set)

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
        smembers, exists, is_trusted = read_with_trust(key)

        if is_trusted
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
          is_trusted = redis.exists?(trust_key(key)) # rubocop:disable CodeReuse/ActiveRecord -- Not ActiveRecord

          write(key, yield) unless is_trusted

          redis.sscan_each(full_key, match: pattern)
        end
      end

      # Override to add trust-awareness.
      # Returns [false, false] when the cache is untrusted, causing the
      # caller (RepositoryCacheAdapter) to fall through to a full lookup
      # which triggers a cache rebuild via #fetch.
      def try_include?(key, value)
        full_key = cache_key(key)

        result, exists, is_trusted = with do |redis|
          redis.multi do |multi|
            multi.sismember(full_key, value.to_s)
            multi.exists?(full_key) # rubocop:disable CodeReuse/ActiveRecord -- Not ActiveRecord
            multi.exists?(trust_key(key)) # rubocop:disable CodeReuse/ActiveRecord -- Not ActiveRecord
          end
        end

        return [false, false] unless is_trusted

        [result, exists]
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
            remove_if_cache_exists(redis, full_key, ref_name)
          else
            add_if_cache_exists(redis, key, full_key, ref_name)
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
            remove_if_cache_exists(redis, full_key, ref_name)
          else
            add_if_cache_exists(redis, key, full_key, ref_name)
          end
        end
      rescue ::Redis::BaseError => e
        log_event(:dual_write_failed, key, level: :error,
          error_class: e.class.name,
          error_message: e.message)
        mark_untrusted(key)
        raise
      end

      # Atomically add ref to the cache set only if the set key exists.
      # Marks cache untrusted when the key is absent (SADD was skipped),
      # so the next fetch triggers a full rebuild.
      # @param redis [Redis] Redis connection
      # @param key [String] Cache key (e.g., :branch_names)
      # @param full_key [String] Full Redis key for the set
      # @param ref_name [String] Short ref name (e.g., "main")
      def add_if_cache_exists(redis, key, full_key, ref_name)
        result = redis.eval(SADD_IF_EXISTS_SCRIPT, keys: [full_key], argv: [ref_name])
        mark_untrusted(key) if result == -1
      end

      # Atomically remove ref from the cache set only if the set key exists.
      # Unlike add, removal from a non-existent set is harmless - no untrust needed.
      # @param redis [Redis] Redis connection
      # @param full_key [String] Full Redis key for the set
      # @param ref_name [String] Short ref name (e.g., "main")
      def remove_if_cache_exists(redis, full_key, ref_name)
        redis.eval(SREM_IF_EXISTS_SCRIPT, keys: [full_key], argv: [ref_name])
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

      # Atomically read the set members, key existence, and trust flag in one
      # round-trip.
      # @return [Array(Array<String>, Boolean, Boolean)] [members, exists, trusted]
      def read_with_trust(key)
        full_key = cache_key(key)

        with do |redis|
          redis.multi do |multi|
            multi.smembers(full_key)
            multi.exists?(full_key) # rubocop:disable CodeReuse/ActiveRecord -- Not ActiveRecord
            multi.exists?(trust_key(key)) # rubocop:disable CodeReuse/ActiveRecord -- Not ActiveRecord
          end
        end
      end

      # Trusts an empty set directly (no key to race). A non-empty set is trusted
      # only if its key survived the rebuild (see TRUST_IF_EXISTS_SCRIPT).
      def grant_trust(key, final_set)
        granted = final_set.empty? ? set_trust_flag(key) : grant_trust_if_present(key)

        return log_event(:rebuild_trust_skipped, key, reason: 'set evicted before trust') unless granted

        log_event(:cache_marked_trusted, key)
      end

      # Grants trust only if the set key still exists.
      def grant_trust_if_present(key)
        full_key = cache_key(key)

        granted = with do |redis|
          redis.eval(TRUST_IF_EXISTS_SCRIPT, keys: [full_key, trust_key(key)], argv: [TRUST_TTL.to_i, FLAG_VALUE])
        end

        granted == 1
      end

      def set_trust_flag(key)
        with { |redis| redis.set(trust_key(key), FLAG_VALUE, ex: TRUST_TTL) }

        true
      end

      # Atomically deletes the trust flag and set for each trust-backed key.
      def expire_with_trust(keys)
        return 0 if keys.empty?

        with do |redis|
          keys.sum do |key|
            redis.eval(EXPIRE_KEY_SCRIPT, keys: [cache_key(key), trust_key(key)])
          end
        end
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
