module Ci
  class RescueStaleLiveTraceWorker
    include ApplicationWorker
    include CronjobQueue

    def perform
      # Archive live traces which still resides in redis or database
      # This could happen when sidekiq-jobs for archivements are lost by SIGKILL
      # Issue: https://gitlab.com/gitlab-org/gitlab-ce/issues/36791
      Ci::BuildTraceChunk.find_builds_from_stale_live_trace do |build_ids|
        Ci::Build.where(id: build_ids).find_each do |build|
          begin
            build.trace.archive!
          rescue => e
            Rails.logger.info "Failed to archive stale live trace. id: #{build.id} message: #{e.message}"
          end
        end
      end
    end
  end
end
