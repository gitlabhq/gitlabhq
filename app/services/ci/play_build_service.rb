# frozen_string_literal: true

module Ci
  class PlayBuildService < ::BaseService
    def execute(build)
      unless can?(current_user, :update_build, build)
        raise Gitlab::Access::AccessDeniedError
      end

      # Try to enqueue the build, otherwise create a duplicate.
      #
      if build.enqueue
        build.tap { |action| action.update(user: current_user) }
      else
        Ci::Build.retry(build, current_user)
      end
    end
  end
end
