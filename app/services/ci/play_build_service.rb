# frozen_string_literal: true

module Ci
  class PlayBuildService < ::BaseService
    def execute(build, job_variables_attributes = nil)
      raise Gitlab::Access::AccessDeniedError unless can?(current_user, :play_job, build)

      if job_variables_attributes.present? && !can?(current_user, :set_pipeline_variables, project)
        raise Gitlab::Access::AccessDeniedError
      end

      # Try to enqueue the build, otherwise create a duplicate.
      #
      if build.enqueue
        build.tap do |build|
          build.update(user: current_user, job_variables_attributes: job_variables_attributes || [])

          next unless ::Feature.enabled?(:ci_fix_pipeline_status_for_dag_needs_manual, project, default_enabled: :yaml)

          AfterRequeueJobService.new(project, current_user).execute(build)
        end
      else
        Ci::Build.retry(build, current_user)
      end
    end
  end
end
