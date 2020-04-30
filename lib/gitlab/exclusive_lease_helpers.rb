# frozen_string_literal: true

module Gitlab
  # This module provides helper methods which are intregrated with GitLab::ExclusiveLease
  module ExclusiveLeaseHelpers
    FailedToObtainLockError = Class.new(StandardError)

    ##
    # This helper method blocks a process/thread until the other process cancel the obrainted lease key.
    #
    # Note: It's basically discouraged to use this method in the unicorn's thread,
    #       because it holds the connection until all `retries` is consumed.
    #       This could potentially eat up all connection pools.
    def in_lock(key, ttl: 1.minute, retries: 10, sleep_sec: 0.01.seconds)
      raise ArgumentError, 'Key needs to be specified' unless key

      lease = Gitlab::ExclusiveLease.new(key, timeout: ttl)
      retried = false
      max_attempts = 1 + retries

      until uuid = lease.try_obtain
        # Keep trying until we obtain the lease. To prevent hammering Redis too
        # much we'll wait for a bit.
        attempt_number = max_attempts - retries
        delay = sleep_sec.respond_to?(:call) ? sleep_sec.call(attempt_number) : sleep_sec

        sleep(delay)
        (retries -= 1) < 0 ? break : retried ||= true
      end

      raise FailedToObtainLockError, 'Failed to obtain a lock' unless uuid

      yield(retried)
    ensure
      Gitlab::ExclusiveLease.cancel(key, uuid)
    end
  end
end
