# frozen_string_literal: true

module Ci
  class ArchiveTraceService
    def execute(job, worker_name:)
      # TODO: Remove this logging once we confirmed new live trace architecture is functional.
      # See https://gitlab.com/gitlab-com/gl-infra/infrastructure/issues/4667.
      unless job.has_live_trace?
        Sidekiq.logger.warn(class: worker_name,
                            message: 'The job does not have live trace but going to be archived.',
                            job_id: job.id)
        return
      end

      job.trace.archive!
      job.remove_pending_state!

      # TODO: Remove this logging once we confirmed new live trace architecture is functional.
      # See https://gitlab.com/gitlab-com/gl-infra/infrastructure/issues/4667.
      unless job.has_archived_trace?
        Sidekiq.logger.warn(class: worker_name,
                            message: 'The job does not have archived trace after archiving.',
                            job_id: job.id)
      end
    rescue ::Gitlab::Ci::Trace::AlreadyArchivedError
      # It's already archived, thus we can safely ignore this exception.
    rescue StandardError => e
      # Tracks this error with application logs, Sentry, and Prometheus.
      # If `archive!` keeps failing for over a week, that could incur data loss.
      # (See more https://docs.gitlab.com/ee/administration/job_logs.html#new-incremental-logging-architecture)
      # In order to avoid interrupting the system, we do not raise an exception here.
      archive_error(e, job, worker_name)
    end

    private

    def failed_archive_counter
      @failed_archive_counter ||=
        Gitlab::Metrics.counter(:job_trace_archive_failed_total,
                                "Counter of failed attempts of trace archiving")
    end

    def archive_error(error, job, worker_name)
      failed_archive_counter.increment

      Sidekiq.logger.warn(class: worker_name,
        message: "Failed to archive trace. message: #{error.message}.",
        job_id: job.id)

      Gitlab::ErrorTracking
        .track_and_raise_for_dev_exception(error,
                          issue_url: 'https://gitlab.com/gitlab-org/gitlab-foss/issues/51502',
                          job_id: job.id )
    end
  end
end
