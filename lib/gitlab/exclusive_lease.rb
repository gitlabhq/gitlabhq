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
    LUA_CANCEL_SCRIPT = <<-EOS
      local key, uuid = KEYS[1], ARGV[1]
      if redis.call("get", key) == uuid then
        redis.call("del", key)
      end
    EOS

    def self.cancel(key, uuid)
      Gitlab::Redis.with do |redis|
        redis.eval(LUA_CANCEL_SCRIPT, keys: [redis_key(key)], argv: [uuid])
      end
    end

    def self.redis_key(key)
      "gitlab:exclusive_lease:#{key}"
    end

    def initialize(key, timeout:)
      @redis_key = self.class.redis_key(key)
      @timeout = timeout
      @uuid = SecureRandom.uuid
    end

    # Try to obtain the lease. Return lease UUID on success,
    # false if the lease is already taken.
    def try_obtain
      # Performing a single SET is atomic
      Gitlab::Redis.with do |redis|
        redis.set(@redis_key, @uuid, nx: true, ex: @timeout) && @uuid
      end
    end

    # Returns true if the key for this lease is set.
    def exists?
      Gitlab::Redis.with do |redis|
        redis.exists(@redis_key)
      end
    end
  end
end
