# frozen_string_literal: true

module Projects
  class RefreshBuildArtifactsSizeStatisticsWorker
    include ApplicationWorker
    include CronjobChildWorker
    include LimitedCapacity::Worker

    data_consistency :always

    feature_category :job_artifacts

    idempotent!

    MAX_RUNNING_LOW = 1
    MAX_RUNNING_MEDIUM = 3
    MAX_RUNNING_HIGH = 5

    def perform_work(*args)
      refresh = Projects::RefreshBuildArtifactsSizeStatisticsService.new.execute
      return unless refresh

      log_extra_metadata_on_done(:refresh_id, refresh.id)
      log_extra_metadata_on_done(:project_id, refresh.project_id)
      log_extra_metadata_on_done(:last_job_artifact_id, refresh.last_job_artifact_id)
      log_extra_metadata_on_done(:last_batch, refresh.destroyed?)
      log_extra_metadata_on_done(:refresh_started_at, refresh.refresh_started_at)
    end

    def remaining_work_count(*args)
      # LimitedCapacity::Worker only needs to know if there is work left to do
      # so we can get by with an EXISTS query rather than a count.
      # https://gitlab.com/gitlab-org/gitlab/-/issues/356167
      if Projects::BuildArtifactsSizeRefresh.remaining.any?
        1
      else
        0
      end
    end

    def max_running_jobs
      if ::Feature.enabled?(:projects_build_artifacts_size_refresh_high, type: :ops)
        MAX_RUNNING_HIGH
      elsif ::Feature.enabled?(:projects_build_artifacts_size_refresh_medium, type: :ops)
        MAX_RUNNING_MEDIUM
      elsif ::Feature.enabled?(:projects_build_artifacts_size_refresh, type: :ops)
        MAX_RUNNING_LOW
      else
        0
      end
    end
  end
end
