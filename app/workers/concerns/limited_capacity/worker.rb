# frozen_string_literal: true

# Usage:
#
# Worker that performs the tasks:
#
# class DummyWorker
#   include ApplicationWorker
#   include LimitedCapacity::Worker
#
#   # For each job that raises any error, a worker instance will be disabled
#   # until the next schedule-run.
#   # If you wish to get around this, exceptions must by handled by the implementer.
#   #
#   def perform_work(*args)
#   end
#
#   def remaining_work_count(*args)
#     5
#   end
#
#   def max_running_jobs
#     25
#   end
# end
#
# Cron worker to fill the pool of regular workers:
#
# class ScheduleDummyCronWorker
#   include ApplicationWorker
#   include CronjobQueue
#
#   def perform(*args)
#     DummyWorker.perform_with_capacity(*args)
#   end
# end
#

module LimitedCapacity
  module Worker
    extend ActiveSupport::Concern
    include Gitlab::Utils::StrongMemoize

    included do
      # Disable Sidekiq retries, log the error, and send the job to the dead queue.
      # This is done to have only one source that produces jobs and because the slot
      # would be occupied by a job that will be performed in the distant future.
      # We let the cron worker enqueue new jobs, this could be seen as our retry and
      # back off mechanism because the job might fail again if executed immediately.
      sidekiq_options retry: 0
      deduplicate :none
    end

    class_methods do
      def perform_with_capacity(*args)
        worker = self.new
        worker.remove_failed_jobs

        arguments = Array.new(worker.max_running_jobs) { args }
        self.bulk_perform_async(arguments) # rubocop:disable Scalability/BulkPerformWithContext
      end
    end

    def perform(*args)
      perform_registered(*args) if job_tracker.register(jid, max_running_jobs)
    end

    def perform_work(*args)
      raise NotImplementedError
    end

    def remaining_work_count(*args)
      raise NotImplementedError
    end

    def max_running_jobs
      raise NotImplementedError
    end

    def remove_failed_jobs
      job_tracker.clean_up
    end

    def report_prometheus_metrics(*args)
      report_running_jobs_metrics
      set_metric(:remaining_work_gauge, remaining_work_count(*args))
      set_metric(:max_running_jobs_gauge, max_running_jobs)
    end

    private

    def perform_registered(*args)
      report_running_jobs_metrics
      perform_work(*args)
    rescue StandardError => exception
      raise
    ensure
      job_tracker.remove(jid)
      report_prometheus_metrics(*args)
      re_enqueue(*args) unless exception
    end

    def report_running_jobs_metrics
      set_metric(:running_jobs_gauge, running_jobs_count)
    end

    def running_jobs_count
      job_tracker.count
    end

    def job_tracker
      strong_memoize(:job_tracker) do
        JobTracker.new(self.class.name)
      end
    end

    def re_enqueue(*args)
      return unless remaining_work_count(*args) > 0

      self.class.perform_async(*args)
    end

    def set_metric(name, value)
      metrics = strong_memoize(:metrics) do
        {
          running_jobs_gauge: Gitlab::Metrics.gauge(:limited_capacity_worker_running_jobs, 'Number of running jobs'),
          max_running_jobs_gauge: Gitlab::Metrics.gauge(:limited_capacity_worker_max_running_jobs, 'Maximum number of running jobs'),
          remaining_work_gauge: Gitlab::Metrics.gauge(:limited_capacity_worker_remaining_work_count, 'Number of jobs waiting to be enqueued')
        }
      end

      metrics[name].set({ worker: self.class.name }, value)
    end
  end
end
