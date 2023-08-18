# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module PauseControl
      class StrategyHandler
        def initialize(worker_class, job)
          @worker_class = worker_class
          @job = job
        end

        # This will continue the middleware chain if the job should be scheduled
        # It will return false if the job needs to be cancelled
        def schedule(&block)
          PauseControl.for(strategy).new.schedule(job, &block)
        end

        # This will continue the server middleware chain if the job should be
        # executed.
        # It will return false if the job should not be executed.
        def perform(&block)
          PauseControl.for(strategy).new.perform(job, &block)
        end

        private

        attr_reader :job, :worker_class

        def strategy
          Gitlab::SidekiqMiddleware::PauseControl::WorkersMap.strategy_for(worker: worker_class)
        end
      end
    end
  end
end
