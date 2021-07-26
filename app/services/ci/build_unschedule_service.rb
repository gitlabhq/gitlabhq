# frozen_string_literal: true

module Ci
  class BuildUnscheduleService
    def initialize(build, user)
      @build = build
      @user = user
    end

    def execute
      return forbidden unless allowed?
      return unprocessable_entity unless build.scheduled?

      build.unschedule!

      ServiceResponse.success(payload: build)
    end

    private

    attr_reader :build, :user

    def allowed?
      user.can?(:update_build, build)
    end

    def forbidden
      ServiceResponse.error(message: 'Forbidden', http_status: :forbidden)
    end

    def unprocessable_entity
      ServiceResponse.error(message: 'Unprocessable entity', http_status: :unprocessable_entity)
    end
  end
end
