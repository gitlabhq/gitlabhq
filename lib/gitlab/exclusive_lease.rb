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
  # This class has no 'cancel' method. I originally decided against adding
  # it because it would add complexity and a false sense of security. The
  # complexity: instead of setting '1' we would have to set a UUID, and to
  # delete it we would have to execute Lua on the Redis server to only
  # delete the key if the value was our own UUID. Otherwise there is a
  # chance that when you intend to cancel your lease you actually delete
  # someone else's. The false sense of security: you cannot design your
  # system to rely too much on the lease being cancelled after use because
  # the calling (Ruby) process may crash or be killed. You _cannot_ count
  # on begin/ensure blocks to cancel a lease, because the 'ensure' does
  # not always run. Think of 'kill -9' from the Unicorn master for
  # instance.
  #
  # If you find that leases are getting in your way, ask yourself: would
  # it be enough to lower the lease timeout? Another thing that might be
  # appropriate is to only use a lease for bulk/automated operations, and
  # to ignore the lease when you get a single 'manual' user request (a
  # button click).
  #
  class ExclusiveLease
    def initialize(key, timeout:)
      @key, @timeout = key, timeout
    end

    # Try to obtain the lease. Return true on success,
    # false if the lease is already taken.
    def try_obtain
      # Performing a single SET is atomic
      Gitlab::Redis.with do |redis|
        !!redis.set(redis_key, '1', nx: true, ex: @timeout)
      end
    end

    # No #cancel method. See comments above!
    # TODO, consider adding this
    #
    def cancel!
      Gitlab::Redis.with { |redis| redis.del(redis_key) }
    end

    private

    def redis_key
      "gitlab:exclusive_lease:#{@key}"
    end
  end
end
