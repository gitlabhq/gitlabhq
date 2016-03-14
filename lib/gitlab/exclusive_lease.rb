module Gitlab
  # This class implements an 'exclusive lease'. We call it a 'lease'
  # because it has a set expiry time. We call it 'exclusive' because only
  # one caller may obtain a lease for a given key at a time. The
  # implementation is intended to work across GitLab processes and across
  # servers. It is a 'cheap' alternative to using SQL queries and updates:
  # you do not need to change the SQL schema to start using
  # ExclusiveLease.
  #
  # It is important to choose the timeout wisely. If the timeout is very
  # high (1 hour) then the throughput of your operation gets very low (at
  # most once an hour). If the timeout is lower than how long your
  # operation may take then you cannot count on exclusivity. For example,
  # if the timeout is 10 seconds and you do an operation which may take 20
  # seconds then two overlapping operations may hold a lease for the same
  # key at the same time.
  #
  class ExclusiveLease
    def initialize(key, timeout:)
      @key, @timeout = key, timeout
    end

    # Try to obtain the lease. Return true on success,
    # false if the lease is already taken.
    def try_obtain
      # Performing a single SET is atomic
      !!redis.set(redis_key, '1', nx: true, ex: @timeout)
    end

    private

    def redis
      # Maybe someday we want to use a connection pool...
      @redis ||= Redis.new(url: Gitlab::RedisConfig.url)
    end

    def redis_key
      "gitlab:exclusive_lease:#{@key}"
    end
  end
end
