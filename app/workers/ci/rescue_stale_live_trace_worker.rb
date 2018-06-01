module Ci
  class RescueStaleLiveTraceWorker
    include ApplicationWorker
    include CronjobQueue

    def perform
      # Archive live traces which still resides in redis or database
      # This could happen when sidekiq-jobs for archivements are lost by SIGKILL
      # Issue: https://gitlab.com/gitlab-org/gitlab-ce/issues/36791
      Ci::Build.find_builds_from_stale_live_traces do |builds|
        builds.each do |build|
          begin
            build.trace.archive!
          rescue => e
            Rails.logger.error "Failed to archive stale live trace. id: #{build.id} message: #{e.message}"
          end
        end
      end
    end
  end
end
