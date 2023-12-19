# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module PauseControl
      class WorkersMap
        class << self
          attr_reader :workers

          def set_strategy_for(strategy:, worker:)
            raise ArgumentError, "Unknown strategy: #{strategy}" unless PauseControl::STRATEGIES.key?(strategy)

            @workers ||= Hash.new { |h, k| h[k] = [] }
            @workers[strategy].push(worker)
          end

          def strategy_for(worker:)
            return unless @workers

            worker_class = worker.is_a?(Class) ? worker : worker.class
            @workers.find { |_, v| v.include?(worker_class) }&.first
          end
        end
      end
    end
  end
end
