# frozen_string_literal: true

module Ci
  module Runners
    class UpdateRunnerService
      attr_reader :runner

      def initialize(runner)
        @runner = runner
      end

      def execute(params)
        params[:active] = !params.delete(:paused) if params.include?(:paused)

        if runner.update(params)
          runner.tick_runner_queue
          ServiceResponse.success
        else
          ServiceResponse.error(message: runner.errors.full_messages)
        end
      end
    end
  end
end
