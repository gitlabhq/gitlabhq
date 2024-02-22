# frozen_string_literal: true

module Gitlab
  # This module provides helper methods which are integrated with GitLab::ExclusiveLease
  module ExclusiveLeaseHelpers
    FailedToObtainLockError = Class.new(StandardError)

    ##
    # This helper method blocks a process/thread until the lease can be acquired, either due to
    # the lease TTL expiring, or due to the current holder explicitly releasing
    # their hold.
    #
    # If the lease cannot be obtained, raises `FailedToObtainLockError`.
    #
    # @param [String] key The lock the thread will try to acquire. Only one thread
    #                     in one process across all Rails instances can hold this named lock at any
    #                     one time.
    # @param [Float] ttl: The length of time the lock will be valid for. The lock
    #                    will be automatically be released after this time, so any work should be
    #                    completed within this time.
    # @param [Integer] retries: The maximum number of times we will re-attempt
    #                           to acquire the lock. The maximum number of attempts will be `retries + 1`:
    #                           one for the initial attempt, and then one for every re-try.
    # @param [Float|Proc] sleep_sec: Either a number of seconds to sleep, or
    #                                a proc that computes the sleep time given the number of preceding attempts
    #                               (from 1 to retries - 1)
    #
    # Note: It's basically discouraged to use this method in a webserver thread,
    #       because this ties up all thread related resources until all `retries` are consumed.
    #       This could potentially eat up all connection pools.
    def in_lock(key, ttl: 1.minute, retries: 10, sleep_sec: 0.01.seconds)
      raise ArgumentError, 'Key needs to be specified' unless key

      Gitlab::Instrumentation::ExclusiveLock.increment_requested_count

      lease = SleepingLock.new(key, timeout: ttl, delay: sleep_sec)

      with_instrumentation(:wait) do
        lease.obtain(1 + retries)
      end

      with_instrumentation(:hold) do
        yield(lease.retried?, lease)
      end
    ensure
      lease&.cancel
    end

    private

    def with_instrumentation(metric)
      start_time = Time.current
      yield
    ensure
      if metric == :wait
        Gitlab::Instrumentation::ExclusiveLock.add_wait_duration(Time.current - start_time)
      else
        Gitlab::Instrumentation::ExclusiveLock.add_hold_duration(Time.current - start_time)
      end
    end
  end
end
