# frozen_string_literal: true

module Ci
  class ArchiveTracesCronWorker
    include ApplicationWorker
    include CronjobQueue

    # rubocop: disable CodeReuse/ActiveRecord
    def perform
      # Archive stale live traces which still resides in redis or database
      # This could happen when ArchiveTraceWorker sidekiq jobs were lost by receiving SIGKILL
      # More details in https://gitlab.com/gitlab-org/gitlab-ce/issues/36791
      Ci::Build.finished.with_live_trace.find_each(batch_size: 100) do |build|
        begin
          build.trace.archive!
        rescue ::Gitlab::Ci::Trace::AlreadyArchivedError
        rescue => e
          failed_archive_counter.increment
          Rails.logger.error "Failed to archive stale live trace. id: #{build.id} message: #{e.message}"
        end
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    private

    def failed_archive_counter
      @failed_archive_counter ||= Gitlab::Metrics.counter(:job_trace_archive_failed_total, "Counter of failed attempts of traces archiving")
    end
  end
end
