module Ci
  class RescueStaleLiveTraceWorker
    include ApplicationWorker
    include CronjobQueue

    def perform
      # Archive stale live traces which still resides in redis or database
      # This could happen when ArchiveTraceWorker sidekiq jobs were lost by receiving SIGKILL
      # More details in https://gitlab.com/gitlab-org/gitlab-ce/issues/36791
      Ci::Build.finished.with_live_trace.find_each(batch_size: 100) do |build|
        begin
          build.trace.archive!
        rescue => e
          Rails.logger.error "Failed to archive stale live trace. id: #{build.id} message: #{e.message}"
        end
      end
    end
  end
end
