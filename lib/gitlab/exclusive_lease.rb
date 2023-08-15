# frozen_string_literal: true

require 'securerandom'

module Gitlab
  # This class implements an 'exclusive lease'. We call it a 'lease'
  # because it has a set expiry time. We call it 'exclusive' because only
  # one caller may obtain a lease for a given key at a time. The
  # implementation is intended to work across GitLab processes and across
  # servers. It is a cheap alternative to using SQL queries and updates:
  # you do not need to change the SQL schema to start using
  # ExclusiveLease.
  #
  class ExclusiveLease
    include Gitlab::Utils::StrongMemoize

    PREFIX = 'gitlab:exclusive_lease'
    NoKey = Class.new(ArgumentError)

    LUA_CANCEL_SCRIPT = <<~EOS
      local key, uuid = KEYS[1], ARGV[1]
      if redis.call("get", key) == uuid then
        redis.call("del", key)
      end
    EOS

    LUA_RENEW_SCRIPT = <<~EOS
      local key, uuid, ttl = KEYS[1], ARGV[1], ARGV[2]
      if redis.call("get", key) == uuid then
        redis.call("expire", key, ttl)
        return uuid
      end
    EOS

    def self.get_uuid(key)
      with_read_redis do |redis|
        redis.get(redis_shared_state_key(key)) || false
      end
    end

    # yield to the {block} at most {count} times per {period}
    #
    # Defaults to once per hour.
    #
    # For example:
    #
    #   # toot the train horn at most every 20min:
    #   throttle(locomotive.id, count: 3, period: 1.hour) { toot_train_horn }
    #   # Brake suddenly at most once every minute:
    #   throttle(locomotive.id, period: 1.minute) { brake_suddenly }
    #   # Specify a uniqueness group:
    #   throttle(locomotive.id, group: :locomotive_brake) { brake_suddenly }
    #
    # If a group is not specified, each block will get a separate group to itself.
    def self.throttle(key, group: nil, period: 1.hour, count: 1, &block)
      group ||= block.source_location.join(':')

      return if new("el:throttle:#{group}:#{key}", timeout: period.to_i / count).waiting?

      yield
    end

    def self.cancel(key, uuid)
      return unless key.present?

      with_write_redis do |redis|
        redis.eval(LUA_CANCEL_SCRIPT, keys: [ensure_prefixed_key(key)], argv: [uuid])
      end
    end

    def self.redis_shared_state_key(key)
      "#{PREFIX}:#{key}"
    end

    def self.ensure_prefixed_key(key)
      raise NoKey unless key.present?

      key.start_with?(PREFIX) ? key : redis_shared_state_key(key)
    end

    # Removes any existing exclusive_lease from redis
    # Don't run this in a live system without making sure no one is using the leases
    def self.reset_all!(scope = '*')
      Gitlab::Redis::SharedState.with do |redis|
        redis.scan_each(match: redis_shared_state_key(scope)).each do |key|
          redis.del(key)
        end
      end

      Gitlab::Redis::ClusterSharedState.with do |redis|
        redis.scan_each(match: redis_shared_state_key(scope)).each do |key|
          redis.del(key)
        end
      end
    end

    def self.use_cluster_shared_state?
      Gitlab::SafeRequestStore[:use_cluster_shared_state] ||=
        Feature.enabled?(:use_cluster_shared_state_for_exclusive_lease)
    end

    def self.use_double_lock?
      Gitlab::SafeRequestStore[:use_double_lock] ||= Feature.enabled?(:enable_exclusive_lease_double_lock_rw)
    end

    def initialize(key, uuid: nil, timeout:)
      @redis_shared_state_key = self.class.redis_shared_state_key(key)
      @timeout = timeout
      @uuid = uuid || SecureRandom.uuid
    end

    # Try to obtain the lease. Return lease UUID on success,
    # false if the lease is already taken.
    def try_obtain
      return try_obtain_with_new_lock if self.class.use_cluster_shared_state?

      # Performing a single SET is atomic
      obtained = set_lease(Gitlab::Redis::SharedState) && @uuid

      # traffic to new store is minimal since only the first lock holder can run SETNX in ClusterSharedState
      return false unless obtained
      return obtained unless self.class.use_double_lock?
      return obtained if same_store # 2nd setnx will surely fail if store are the same

      second_lock_obtained = set_lease(Gitlab::Redis::ClusterSharedState) && @uuid

      # cancel is safe since it deletes key only if value matches uuid
      # i.e. it will not delete the held lock on ClusterSharedState
      cancel unless second_lock_obtained

      second_lock_obtained
    end

    # This lease is waiting to obtain
    def waiting?
      !try_obtain
    end

    # Try to renew an existing lease. Return lease UUID on success,
    # false if the lease is taken by a different UUID or inexistent.
    def renew
      self.class.with_write_redis do |redis|
        result = redis.eval(LUA_RENEW_SCRIPT, keys: [@redis_shared_state_key], argv: [@uuid, @timeout])
        result == @uuid
      end
    end

    # Returns true if the key for this lease is set.
    def exists?
      self.class.with_read_redis do |redis|
        redis.exists?(@redis_shared_state_key) # rubocop:disable CodeReuse/ActiveRecord
      end
    end

    # Returns the TTL of the Redis key.
    #
    # This method will return `nil` if no TTL could be obtained.
    def ttl
      self.class.with_read_redis do |redis|
        ttl = redis.ttl(@redis_shared_state_key)

        ttl if ttl > 0
      end
    end

    # rubocop:disable CodeReuse/ActiveRecord
    def self.with_write_redis(&blk)
      if use_cluster_shared_state?
        result = Gitlab::Redis::ClusterSharedState.with(&blk)
        Gitlab::Redis::SharedState.with(&blk)

        result
      elsif use_double_lock?
        result = Gitlab::Redis::SharedState.with(&blk)
        Gitlab::Redis::ClusterSharedState.with(&blk)

        result
      else
        Gitlab::Redis::SharedState.with(&blk)
      end
    end

    def self.with_read_redis(&blk)
      if use_cluster_shared_state?
        Gitlab::Redis::ClusterSharedState.with(&blk)
      elsif use_double_lock?
        Gitlab::Redis::SharedState.with(&blk) || Gitlab::Redis::ClusterSharedState.with(&blk)
      else
        Gitlab::Redis::SharedState.with(&blk)
      end
    end
    # rubocop:enable CodeReuse/ActiveRecord

    # Gives up this lease, allowing it to be obtained by others.
    def cancel
      self.class.cancel(@redis_shared_state_key, @uuid)
    end

    private

    def set_lease(redis_class)
      redis_class.with do |redis|
        redis.set(@redis_shared_state_key, @uuid, nx: true, ex: @timeout)
      end
    end

    def try_obtain_with_new_lock
      # checks shared-state to avoid 2 versions of the application acquiring 1 lock
      # wait for held lock to expire or yielded in case any process on old version is running
      return false if Gitlab::Redis::SharedState.with { |c| c.exists?(@redis_shared_state_key) } # rubocop:disable CodeReuse/ActiveRecord

      set_lease(Gitlab::Redis::ClusterSharedState) && @uuid
    end

    def same_store
      Gitlab::Redis::ClusterSharedState.with(&:id) == Gitlab::Redis::SharedState.with(&:id) # rubocop:disable CodeReuse/ActiveRecord
    end
    strong_memoize_attr :same_store
  end
end

Gitlab::ExclusiveLease.prepend_mod_with('Gitlab::ExclusiveLease')
