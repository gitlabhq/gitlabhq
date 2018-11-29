# frozen_string_literal: true

module Ci
  class ArchiveTraceService
    def execute(job)
      job.trace.archive!
    rescue ::Gitlab::Ci::Trace::AlreadyArchivedError
      # It's already archived, thus we can safely ignore this exception.
    rescue => e
      archive_error(e, job)
    end

    private

    def failed_archive_counter
      @failed_archive_counter ||= Gitlab::Metrics.counter(:job_trace_archive_failed_total, "Counter of failed attempts of trace archiving")
    end

    def archive_error(error, job)
      failed_archive_counter.increment
      Gitlab::Sentry.track_exception(error, issue_url: 'https://gitlab.com/gitlab-org/gitlab-ce/issues/51502', extra: { job_id: job.id })
      Rails.logger.error "Failed to archive trace. id: #{job.id} message: #{error.message}"
    end
  end
end
