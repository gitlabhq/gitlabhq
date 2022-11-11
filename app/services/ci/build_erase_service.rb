# frozen_string_literal: true

module Ci
  class BuildEraseService
    include BaseServiceUtility

    def initialize(build, current_user)
      @build = build
      @current_user = current_user
    end

    def execute
      unless build.erasable?
        return ServiceResponse.error(message: _('Build cannot be erased'), http_status: :unprocessable_entity)
      end

      if build.project.refreshing_build_artifacts_size?
        Gitlab::ProjectStatsRefreshConflictsLogger.warn_artifact_deletion_during_stats_refresh(
          method: 'Ci::BuildEraseService#execute',
          project_id: build.project_id
        )
      end

      destroy_artifacts
      erase_trace!
      update_erased!

      ServiceResponse.success(payload: build)
    end

    private

    attr_reader :build, :current_user

    def destroy_artifacts
      Ci::JobArtifacts::DestroyBatchService.new(build.job_artifacts).execute
    end

    def erase_trace!
      build.trace.erase!
    end

    def update_erased!
      build.update(erased_by: current_user, erased_at: Time.current, artifacts_expire_at: nil)
    end
  end
end
