module Gitlab
  # JobWaiter can be used to wait for a number of Sidekiq jobs to complete.
  #
  # Its use requires the cooperation of the sidekiq jobs themselves. Set up the
  # waiter, then start the jobs, passing them its `key`. Their `perform` methods
  # should look like:
  #
  #     def perform(args, notify_key)
  #       # do work
  #     ensure
  #       ::Gitlab::JobWaiter.notify(notify_key, jid)
  #     end
  #
  # The JobWaiter blocks popping items from a Redis array. All the sidekiq jobs
  # push to that array when done. Once the waiter has popped `count` items, it
  # knows all the jobs are done.
  class JobWaiter
    KEY_PREFIX = "gitlab:job_waiter".freeze

    def self.notify(key, jid)
      Gitlab::Redis::SharedState.with { |redis| redis.lpush(key, jid) }
    end

    def self.key?(key)
      key.is_a?(String) && key =~ /\A#{KEY_PREFIX}:\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/
    end

    attr_reader :key, :finished
    attr_accessor :jobs_remaining

    # jobs_remaining - the number of jobs left to wait for
    # key - The key of this waiter.
    def initialize(jobs_remaining = 0, key = "#{KEY_PREFIX}:#{SecureRandom.uuid}")
      @key = key
      @jobs_remaining = jobs_remaining
      @finished = []
    end

    # Waits for all the jobs to be completed.
    #
    # timeout - The maximum amount of seconds to block the caller for. This
    #           ensures we don't indefinitely block a caller in case a job takes
    #           long to process, or is never processed.
    def wait(timeout = 10)
      deadline = Time.now.utc + timeout

      Gitlab::Redis::SharedState.with do |redis|
        # Fallback key expiry: allow a long grace period to reduce the chance of
        # a job pushing to an expired key and recreating it
        redis.expire(key, [timeout * 2, 10.minutes.to_i].max)

        while jobs_remaining > 0
          # Redis will not take fractional seconds. Prefer waiting too long over
          # not waiting long enough
          seconds_left = (deadline - Time.now.utc).ceil

          # Redis interprets 0 as "wait forever", so skip the final `blpop` call
          break if seconds_left <= 0

          list, jid = redis.blpop(key, timeout: seconds_left)
          break unless list && jid # timed out

          @finished << jid
          @jobs_remaining -= 1
        end

        # All jobs have finished, so expire the key immediately
        redis.expire(key, 0) if jobs_remaining == 0
      end

      finished
    end
  end
end
