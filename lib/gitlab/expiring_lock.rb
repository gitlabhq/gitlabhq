module Gitlab
  # This class implements a distributed self-expiring lock.
  #
  # [2] pry(main)> l = Gitlab::ExpiringLock.new('foobar', 5)
  # => #<Gitlab::ExpiringLock:0x007ffb9d7cb7f8 @key="foobar", @timeout=5>
  # [3] pry(main)> l.try_lock
  # => true
  # [4] pry(main)> l.try_lock # Only the first try_lock succeeds
  # => false
  # [5] pry(main)> l.locked?
  # => true
  # [6] pry(main)> sleep 5
  # => 5
  # [7] pry(main)> l.locked? # After the timeout the lock is released
  # => false
  #
  class ExpiringLock
    def initialize(key, timeout)
      @key, @timeout = key, timeout
    end

    # Try to obtain the lock. Return true on succes,
    # false if the lock is already taken.
    def try_lock
      # INCR does not change the key TTL
      if redis.incr(redis_key) == 1
        # We won the race to insert the key into Redis
        redis.expire(redis_key, @timeout)
        true
      else
        # Somebody else won the race
        false
      end
    end

    # Check if somebody somewhere locked this key
    def locked?
      !!redis.get(redis_key)
    end

    private

    def redis
      # Maybe someday we want to use a connection pool...
      @redis ||= Redis.new(url: Gitlab::RedisConfig.url)
    end

    def redis_key
      "gitlab:expiring_lock:#{@key}"
    end
  end
end
