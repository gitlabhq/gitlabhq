# frozen_string_literal: true

module Ci
  class BuildEraseService
    include BaseServiceUtility
    include Ci::JobRateLimitable

    # @rate_limit - false for internal callers (for example, admin console
    #   cleanup scripts) that must never be throttled
    def initialize(build, current_user, rate_limit: true)
      @build = build
      @current_user = current_user
      @rate_limit = rate_limit
    end

    def execute
      throttled_response = rate_limited_response
      return throttled_response if throttled_response

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

    def project
      build.project
    end

    def rate_limit?
      @rate_limit
    end

    def rate_limited_response
      return unless Feature.enabled?(:rate_limit_job_erase, project)

      job_rate_limited_response(
        build, key: :job_erase, per_project_key: :job_erase_per_project, log_message: 'Job erase rate limit exceeded'
      )
    end

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
