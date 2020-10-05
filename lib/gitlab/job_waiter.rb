# frozen_string_literal: true

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
    KEY_PREFIX = "gitlab:job_waiter"

    STARTED_METRIC = :gitlab_job_waiter_started_total
    TIMEOUTS_METRIC = :gitlab_job_waiter_timeouts_total

    def self.notify(key, jid)
      Gitlab::Redis::SharedState.with do |redis|
        # Use a Redis MULTI transaction to ensure we always set an expiry
        redis.multi do |multi|
          multi.lpush(key, jid)
          # This TTL needs to be long enough to allow whichever Sidekiq job calls
          # JobWaiter#wait to reach BLPOP.
          multi.expire(key, 6.hours.to_i)
        end
      end
    end

    def self.key?(key)
      key.is_a?(String) && key =~ /\A#{KEY_PREFIX}:\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/
    end

    attr_reader :key, :finished, :worker_label
    attr_accessor :jobs_remaining

    # jobs_remaining - the number of jobs left to wait for
    # key - The key of this waiter.
    def initialize(jobs_remaining = 0, key = "#{KEY_PREFIX}:#{SecureRandom.uuid}", worker_label: nil)
      @key = key
      @jobs_remaining = jobs_remaining
      @finished = []
      @worker_label = worker_label
    end

    # Waits for all the jobs to be completed.
    #
    # timeout - The maximum amount of seconds to block the caller for. This
    #           ensures we don't indefinitely block a caller in case a job takes
    #           long to process, or is never processed.
    def wait(timeout = 10)
      deadline = Time.now.utc + timeout
      increment_counter(STARTED_METRIC)

      Gitlab::Redis::SharedState.with do |redis|
        while jobs_remaining > 0
          # Redis will not take fractional seconds. Prefer waiting too long over
          # not waiting long enough
          seconds_left = (deadline - Time.now.utc).ceil

          # Redis interprets 0 as "wait forever", so skip the final `blpop` call
          break if seconds_left <= 0

          list, jid = redis.blpop(key, timeout: seconds_left)

          # timed out
          unless list && jid
            increment_counter(TIMEOUTS_METRIC)
            break
          end

          @finished << jid
          @jobs_remaining -= 1
        end
      end

      finished
    end

    private

    def increment_counter(metric)
      return unless worker_label

      metrics[metric].increment(worker: worker_label)
    end

    def metrics
      @metrics ||= {
        STARTED_METRIC => Gitlab::Metrics.counter(STARTED_METRIC, 'JobWaiter attempts started'),
        TIMEOUTS_METRIC => Gitlab::Metrics.counter(TIMEOUTS_METRIC, 'JobWaiter attempts timed out')
      }
    end
  end
end
