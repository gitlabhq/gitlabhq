# frozen_string_literal: true

module Ci
  class RunScheduledBuildService < ::BaseService
    def execute(build)
      unless can?(current_user, :update_build, build)
        raise Gitlab::Access::AccessDeniedError
      end

      build.enqueue_scheduled!
    end
  end
end
