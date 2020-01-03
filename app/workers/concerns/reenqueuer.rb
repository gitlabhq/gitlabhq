# frozen_string_literal: true

#
# A concern that helps run exactly one instance of a worker, over and over,
# until it returns false or raises.
#
# To ensure the worker is always up, you can schedule it every minute with
# sidekiq-cron. Excess jobs will immediately exit due to an exclusive lease.
#
# The worker must define:
#
#   - `#perform`
#   - `#lease_timeout`
#
# The worker spec should include `it_behaves_like 'reenqueuer'` and
# `it_behaves_like 'it is rate limited to 1 call per'`.
#
# Optionally override `#minimum_duration` to adjust the rate limit.
#
# When `#perform` returns false, the job will not be reenqueued. Instead, we
# will wait for the next one scheduled by sidekiq-cron.
#
# #lease_timeout should be longer than the longest possible `#perform`.
# The lease is normally released in an ensure block, but it is possible to
# orphan the lease by killing Sidekiq, so it should also be as short as
# possible. Consider that long-running jobs are generally not recommended.
# Ideally, every job finishes within 25 seconds because that is the default
# wait time for graceful termination.
#
# Timing: It runs as often as Sidekiq allows. We rate limit with sleep for
# now: https://gitlab.com/gitlab-org/gitlab/issues/121697
module Reenqueuer
  extend ActiveSupport::Concern

  prepended do
    include ExclusiveLeaseGuard
    include ReenqueuerSleeper

    sidekiq_options retry: false
  end

  def perform(*args)
    try_obtain_lease do
      reenqueue(*args) do
        ensure_minimum_duration(minimum_duration) do
          super
        end
      end
    end
  end

  private

  def reenqueue(*args)
    self.class.perform_async(*args) if yield
  end

  # Override as needed
  def minimum_duration
    5.seconds
  end

  # We intend to get rid of sleep:
  # https://gitlab.com/gitlab-org/gitlab/issues/121697
  module ReenqueuerSleeper
    # The block will run, and then sleep until the minimum duration. Returns the
    # block's return value.
    #
    # Usage:
    #
    #   ensure_minimum_duration(5.seconds) do
    #     # do something
    #   end
    #
    def ensure_minimum_duration(minimum_duration)
      start_time = Time.now

      result = yield

      sleep_if_time_left(minimum_duration, start_time)

      result
    end

    private

    def sleep_if_time_left(minimum_duration, start_time)
      time_left = calculate_time_left(minimum_duration, start_time)

      sleep(time_left) if time_left > 0
    end

    def calculate_time_left(minimum_duration, start_time)
      minimum_duration - elapsed_time(start_time)
    end

    def elapsed_time(start_time)
      Time.now - start_time
    end
  end
end
