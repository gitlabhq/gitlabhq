require 'securerandom'

module Gitlab
  # This class implements an 'exclusive lease'. We call it a 'lease'
  # because it has a set expiry time. We call it 'exclusive' because only
  # one caller may obtain a lease for a given key at a time. The
  # implementation is intended to work across GitLab processes and across
  # servers. It is a 'cheap' alternative to using SQL queries and updates:
  # you do not need to change the SQL schema to start using
  # ExclusiveLease.
  class ExclusiveLease
    def initialize(key, timeout)
      @key, @timeout = key, timeout
    end

    # Try to obtain the lease. Return true on succes,
    # false if the lease is already taken.
    def try_obtain
      !!redis.set(redis_key, redis_value, nx: true, ex: @timeout)
    end

    private

    def redis
      # Maybe someday we want to use a connection pool...
      @redis ||= Redis.new(url: Gitlab::RedisConfig.url)
    end

    def redis_key
      "gitlab:exclusive_lease:#{@key}"
    end

    def redis_value
      @redis_value ||= SecureRandom.hex(10)
    end
  end
end
