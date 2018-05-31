module Ci
  class RescueStaleLiveTraceWorker
    include ApplicationWorker
    include CronjobQueue

    def perform
      # Reschedule to archive live traces
      #
      # The targets are jobs with the following conditions
      # - Jobs had been finished 1 hour ago, but they don't have an archived trace yet
      #   This could happen when their sidekiq-jobs are lost by SIGKILL
      Ci::BuildTraceChunk.find_stale_in_batches(finished_before: 1.hour.ago) do |build_ids|
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
