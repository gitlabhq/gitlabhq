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
    LeaseWithinTransactionError = Class.new(StandardError)

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
      Gitlab::Redis::SharedState.with do |redis|
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
      return unless uuid.present?

      Gitlab::Redis::SharedState.with do |redis|
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
    end

    def self.set_skip_transaction_check_flag(flag = nil)
      Thread.current[:skip_transaction_check_for_exclusive_lease] = flag
    end

    def self.skip_transaction_check?
      Thread.current[:skip_transaction_check_for_exclusive_lease]
    end

    def self.skipping_transaction_check
      previous_skip_transaction_check = skip_transaction_check?
      set_skip_transaction_check_flag(true)

      yield
    ensure
      set_skip_transaction_check_flag(previous_skip_transaction_check)
    end

    def initialize(key, timeout:, uuid: nil)
      @redis_shared_state_key = self.class.redis_shared_state_key(key)
      @timeout = timeout
      @uuid = uuid || SecureRandom.uuid
    end

    # Try to obtain the lease. Return lease UUID on success,
    # false if the lease is already taken.
    def try_obtain
      report_lock_attempt_inside_transaction unless self.class.skip_transaction_check?

      # Performing a single SET is atomic
      Gitlab::Redis::SharedState.with do |redis|
        redis.set(@redis_shared_state_key, @uuid, nx: true, ex: @timeout) && @uuid
      end
    end

    def report_lock_attempt_inside_transaction
      return unless ::ApplicationRecord.inside_transaction? || ::Ci::ApplicationRecord.inside_transaction?

      raise LeaseWithinTransactionError,
        "Exclusive lease cannot be obtained within a transaction as it could lead to idle transactions."
    rescue LeaseWithinTransactionError => e
      Gitlab::ErrorTracking.track_and_raise_for_dev_exception(
        e, issue_url: "https://gitlab.com/gitlab-org/gitlab/-/issues/440368"
      )
    end

    # This lease is waiting to obtain
    def waiting?
      !try_obtain
    end

    # Try to renew an existing lease. Return lease UUID on success,
    # false if the lease is taken by a different UUID or inexistent.
    def renew
      Gitlab::Redis::SharedState.with do |redis|
        result = redis.eval(LUA_RENEW_SCRIPT, keys: [@redis_shared_state_key], argv: [@uuid, @timeout.to_i])
        result == @uuid
      end
    end

    # Returns true if the key for this lease is set.
    def exists?
      Gitlab::Redis::SharedState.with do |redis|
        redis.exists?(@redis_shared_state_key) # rubocop:disable CodeReuse/ActiveRecord
      end
    end

    # Returns the TTL of the Redis key.
    #
    # This method will return `nil` if no TTL could be obtained.
    def ttl
      Gitlab::Redis::SharedState.with do |redis|
        ttl = redis.ttl(@redis_shared_state_key)

        ttl if ttl > 0
      end
    end

    # Gives up this lease, allowing it to be obtained by others.
    def cancel
      self.class.cancel(@redis_shared_state_key, @uuid)
    end
  end
end

Gitlab::ExclusiveLease.prepend_mod_with('Gitlab::ExclusiveLease')
