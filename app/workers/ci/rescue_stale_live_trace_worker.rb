module Ci
  class RescueStaleLiveTraceWorker
    include ApplicationWorker
    include CronjobQueue

    def perform
      # Reschedule to archive live traces
      #
      # The targets are jobs with the following conditions
      # - It had been finished 1 hour ago, but it has not had an acthived trace yet
      #   This case happens when sidekiq-jobs of archiving traces are lost in order to restart sidekiq instace which hit RSS limit
      Ci::BuildTraceChunk.find_stale(finished_before: 1.hour.ago) do |build_ids|
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
