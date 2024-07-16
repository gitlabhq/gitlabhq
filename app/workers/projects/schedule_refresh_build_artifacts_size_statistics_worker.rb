# frozen_string_literal: true

module Projects
  class ScheduleRefreshBuildArtifactsSizeStatisticsWorker
    include ApplicationWorker
    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

    data_consistency :always

    feature_category :job_artifacts

    idempotent!

    def perform
      Projects::RefreshBuildArtifactsSizeStatisticsWorker.perform_with_capacity
    end
  end
end
