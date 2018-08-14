# frozen_string_literal: true
module Ci
  class EnqueueBuildService < BaseService
    def execute(build)
      build.enqueue
    end
  end
end
