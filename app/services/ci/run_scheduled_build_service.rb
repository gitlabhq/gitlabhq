# frozen_string_literal: true

module Ci
  class RunScheduledBuildService
    def initialize(build)
      @build = build
    end

    def execute
      raise Gitlab::Access::AccessDeniedError unless Ability.allowed?(build.user, :update_build, build)

      build.enqueue_scheduled!
    end

    attr_reader :build
  end
end
