# frozen_string_literal: true

module CronSchedulable
  extend ActiveSupport::Concern
  include Schedulable

  ##
  # The `next_run_at` column is set to the actual execution date of worker that
  # triggers the schedule. This way, a schedule like `*/1 * * * *` won't be triggered
  # in a short interval when the worker runs irregularly by Sidekiq Memory Killer.
  def set_next_run_at
    now = Time.zone.now
    ideal_next_run = ideal_next_run_from(now)

    self.next_run_at = if ideal_next_run == cron_worker_next_run_from(now)
                         ideal_next_run
                       else
                         cron_worker_next_run_from(ideal_next_run)
                       end
  end

  private

  def ideal_next_run_from(start_time)
    next_time_from(start_time, cron, cron_timezone)
  end

  def cron_worker_next_run_from(start_time)
    next_time_from(start_time, worker_cron_expression, Time.zone.name)
  end

  def next_time_from(start_time, cron, cron_timezone)
    Gitlab::Ci::CronParser
      .new(cron, cron_timezone)
      .next_time_from(start_time)
  end

  def worker_cron_expression
    raise NotImplementedError
  end
end
