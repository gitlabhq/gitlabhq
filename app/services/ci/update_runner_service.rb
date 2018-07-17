# frozen_string_literal: true

module Ci
  class UpdateRunnerService
    attr_reader :runner

    def initialize(runner)
      @runner = runner
    end

    def update(params)
      runner.update(params).tap do |updated|
        runner.tick_runner_queue if updated
      end
    end
  end
end
