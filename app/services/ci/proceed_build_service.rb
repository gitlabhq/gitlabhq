# frozen_string_literal: true

module Ci
  class ProceedBuildService < BaseService
    def execute(build)
      if build.schedulable?
        build.schedule!
      elsif build.action?
        build.actionize
      else
        build.enqueue
      end
    end
  end
end
