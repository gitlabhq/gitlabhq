# frozen_string_literal: true

module Ci
  class BuildCancelService
    def initialize(build, user, force = false)
      @build = build
      @user = user
      @force = force
    end

    def execute
      return forbidden unless allowed?
      return unprocessable_entity unless build.cancelable? || (force && allowed_to_force?)

      if force
        build.force_cancel
      else
        build.cancel
      end

      ServiceResponse.success(payload: build)
    end

    private

    attr_reader :build, :user, :force

    def allowed?
      user.can?(:cancel_build, build)
    end

    def allowed_to_force?
      build.force_cancelable? && user.can?(:maintainer_access, build)
    end

    def forbidden
      ServiceResponse.error(message: 'Forbidden', http_status: :forbidden)
    end

    def unprocessable_entity
      ServiceResponse.error(message: 'Unprocessable entity', http_status: :unprocessable_entity)
    end
  end
end
