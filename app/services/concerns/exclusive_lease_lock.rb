module ExclusiveLeaseLock
  extend ActiveSupport::Concern

  def in_lock(key, ttl: 1.minute, retry_max: 10, sleep_sec: 0.01.seconds)
    lease = Gitlab::ExclusiveLease.new(key, timeout: ttl)
    retry_count = 0

    until uuid = lease.try_obtain
      # Keep trying until we obtain the lease. To prevent hammering Redis too
      # much we'll wait for a bit.
      sleep(sleep_sec)
      break if retry_max < (retry_count += 1)
    end

    raise WriteError, 'Failed to obtain write lock' unless uuid

    return yield
  ensure
    Gitlab::ExclusiveLease.cancel(key, uuid)
  end
end
