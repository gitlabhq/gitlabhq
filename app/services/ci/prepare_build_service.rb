# frozen_string_literal: true

module Ci
  class PrepareBuildService
    attr_reader :build

    def initialize(build)
      @build = build
    end

    def execute
      prerequisites.each(&:complete!)

      unless build.enqueue
        build.drop!(:unmet_prerequisites)
      end
    end

    private

    def prerequisites
      build.prerequisites
    end
  end
end
