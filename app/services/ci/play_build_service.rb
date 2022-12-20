# frozen_string_literal: true

module Ci
  class PlayBuildService < ::BaseService
    def execute(build, job_variables_attributes = nil)
      check_access!(build, job_variables_attributes)

      Ci::EnqueueJobService.new(build, current_user: current_user, variables: job_variables_attributes || []).execute
    rescue StateMachines::InvalidTransition
      retry_build(build.reset)
    end

    private

    def retry_build(build)
      Ci::RetryJobService.new(project, current_user).execute(build)[:job]
    end

    def check_access!(build, job_variables_attributes)
      raise Gitlab::Access::AccessDeniedError unless can?(current_user, :play_job, build)

      if job_variables_attributes.present? && !can?(current_user, :set_pipeline_variables, project)
        raise Gitlab::Access::AccessDeniedError
      end
    end
  end
end

Ci::PlayBuildService.prepend_mod_with('Ci::PlayBuildService')
