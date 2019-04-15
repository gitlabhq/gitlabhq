# frozen_string_literal: true

module Ci
  class PrepareBuildService
    attr_reader :build

    def initialize(build)
      @build = build
    end

    def execute
      prerequisites.each(&:complete!)

      build.enqueue!
    rescue => e
      Gitlab::Sentry.track_acceptable_exception(e, extra: { build_id: build.id })

      build.drop(:unmet_prerequisites)
    end

    private

    def prerequisites
      build.prerequisites
    end
  end
end
