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
        build.tap { |action| action.update(user: current_user, job_variables_attributes: job_variables_attributes || []) }
      else
        Ci::Build.retry(build, current_user)
      end
    end
  end
end
