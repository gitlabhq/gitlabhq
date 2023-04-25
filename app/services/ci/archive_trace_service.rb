# frozen_string_literal: true

module Ci
  class ArchiveTraceService
    include ::Gitlab::ExclusiveLeaseHelpers

    EXCLUSIVE_LOCK_KEY = 'archive_trace_service:batch_execute:lock'
    LOCK_TIMEOUT = 56.minutes
    LOOP_TIMEOUT = 55.minutes
    LOOP_LIMIT = 2000
    BATCH_SIZE = 100

    # rubocop: disable CodeReuse/ActiveRecord
    def batch_execute(worker_name:)
      start_time = Time.current
      in_lock(EXCLUSIVE_LOCK_KEY, ttl: LOCK_TIMEOUT, retries: 1) do
        Ci::Build.with_stale_live_trace.find_each(batch_size: BATCH_SIZE).with_index do |build, index|
          break if Time.current - start_time > LOOP_TIMEOUT

          if index > LOOP_LIMIT
            Sidekiq.logger.warn(class: worker_name, message: 'Loop limit reached.', job_id: build.id)
            break
          end

          begin
            execute(build, worker_name: worker_name)
          rescue StandardError
            next
          end
        end
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def execute(job, worker_name:)
      unless job.trace.archival_attempts_available?
        Sidekiq.logger.warn(class: worker_name, message: 'The job is out of archival attempts.', job_id: job.id)

        job.trace.attempt_archive_cleanup!
        return
      end

      unless job.trace.can_attempt_archival_now?
        Sidekiq.logger.warn(class: worker_name, message: 'The job can not be archived right now.', job_id: job.id)
        return
      end

      job.trace.archive!
      job.remove_pending_state!

      if job.job_artifacts_trace.present?
        job.project.execute_integrations(Gitlab::DataBuilder::ArchiveTrace.build(job), :archive_trace_hooks)
      end
    rescue ::Gitlab::Ci::Trace::AlreadyArchivedError
      # It's already archived, thus we can safely ignore this exception.
    rescue StandardError => e
      job.trace.increment_archival_attempts!

      # Tracks this error with application logs, Sentry, and Prometheus.
      # If `archive!` keeps failing for over a week, that could incur data loss.
      # (See more https://docs.gitlab.com/ee/administration/job_logs.html#new-incremental-logging-architecture)
      # In order to avoid interrupting the system, we do not raise an exception here.
      archive_error(e, job, worker_name)
    end

    private

    def failed_archive_counter
      @failed_archive_counter ||=
        Gitlab::Metrics.counter(:job_trace_archive_failed_total, "Counter of failed attempts of trace archiving")
    end

    def archive_error(error, job, worker_name)
      failed_archive_counter.increment

      Sidekiq.logger.warn(
        class: worker_name,
        message: "Failed to archive trace. message: #{error.message}.",
        job_id: job.id
      )

      Gitlab::ErrorTracking.track_and_raise_for_dev_exception(
        error,
        issue_url: 'https://gitlab.com/gitlab-org/gitlab-foss/issues/51502',
        job_id: job.id
      )
    end
  end
end
