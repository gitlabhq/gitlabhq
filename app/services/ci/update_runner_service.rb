module Ci
  class UpdateRunnerService
    attr_reader :runner

    def initialize(runner)
      @runner = runner
    end

    def update(params)
      runner.update(params).tap do
        runner.tick_runner_queue
      end
    end
  end
end
