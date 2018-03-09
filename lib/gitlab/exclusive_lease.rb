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
    LUA_CANCEL_SCRIPT = <<~EOS.freeze
      local key, uuid = KEYS[1], ARGV[1]
      if redis.call("get", key) == uuid then
        redis.call("del", key)
      end
    EOS

    LUA_RENEW_SCRIPT = <<~EOS.freeze
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

    def self.cancel(key, uuid)
      Gitlab::Redis::SharedState.with do |redis|
        redis.eval(LUA_CANCEL_SCRIPT, keys: [redis_shared_state_key(key)], argv: [uuid])
      end
    end

    def self.redis_shared_state_key(key)
      "gitlab:exclusive_lease:#{key}"
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

    def initialize(key, uuid: nil, timeout:)
      @redis_shared_state_key = self.class.redis_shared_state_key(key)
      @timeout = timeout
      @uuid = uuid || SecureRandom.uuid
    end

    # Try to obtain the lease. Return lease UUID on success,
    # false if the lease is already taken.
    def try_obtain
      # Performing a single SET is atomic
      Gitlab::Redis::SharedState.with do |redis|
        redis.set(@redis_shared_state_key, @uuid, nx: true, ex: @timeout) && @uuid
      end
    end

    # Try to renew an existing lease. Return lease UUID on success,
    # false if the lease is taken by a different UUID or inexistent.
    def renew
      Gitlab::Redis::SharedState.with do |redis|
        result = redis.eval(LUA_RENEW_SCRIPT, keys: [@redis_shared_state_key], argv: [@uuid, @timeout])
        result == @uuid
      end
    end

    # Returns true if the key for this lease is set.
    def exists?
      Gitlab::Redis::SharedState.with do |redis|
        redis.exists(@redis_shared_state_key)
      end
    end

    # Returns the TTL of the Redis key.
    #
    # This method will return `nil` if no TTL could be obtained.
    def ttl
      Gitlab::Redis::SharedState.with do |redis|
        ttl = redis.ttl(@redis_shared_state_key)

        ttl if ttl.positive?
      end
    end
  end
end
