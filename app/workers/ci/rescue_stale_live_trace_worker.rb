module Ci
  class RescueStaleLiveTraceWorker
    include ApplicationWorker
    include CronjobQueue

    def perform
      # Archive stale live traces which still resides in redis or database
      # This could happen when ArchiveTraceWorker sidekiq jobs were lost by receiving SIGKILL
      # More details in https://gitlab.com/gitlab-org/gitlab-ce/issues/36791
      failed_archive_counter = Gitlab::Metrics.counter(:job_stale_live_trace_failed_archive_total, "Counter of failed archiving with stale live trace")

      Ci::Build.finished.with_live_trace.find_each(batch_size: 100) do |build|
        begin
          build.trace.archive!
        rescue => e
          failed_archive_counter.increment
          Rails.logger.error "Failed to archive stale live trace. id: #{build.id} message: #{e.message}"
        end
      end
    end
  end
end
