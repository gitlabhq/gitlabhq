# frozen_string_literal: true
module Ci
  class EnqueueBuildService < BaseService
    prepend EE::Ci::EnqueueBuildService

    def execute(build)
      build.enqueue
    end
  end
end
