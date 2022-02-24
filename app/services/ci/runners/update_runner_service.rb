# frozen_string_literal: true

module Ci
  module Runners
    class UpdateRunnerService
      attr_reader :runner

      def initialize(runner)
        @runner = runner
      end

      def update(params)
        params[:active] = !params.delete(:paused) if params.include?(:paused)

        runner.update(params).tap do |updated|
          runner.tick_runner_queue if updated
        end
      end
    end
  end
end
