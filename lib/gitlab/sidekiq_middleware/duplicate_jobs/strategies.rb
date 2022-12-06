# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module DuplicateJobs
      module Strategies
        UnknownStrategyError = Class.new(StandardError)

        STRATEGIES = {
          until_executing: ::Gitlab::SidekiqMiddleware::DuplicateJobs::Strategies::UntilExecuting,
          until_executed: ::Gitlab::SidekiqMiddleware::DuplicateJobs::Strategies::UntilExecuted,
          none: ::Gitlab::SidekiqMiddleware::DuplicateJobs::Strategies::None
        }.freeze

        def self.for(name)
          STRATEGIES.fetch(name)
        rescue KeyError
          raise UnknownStrategyError, "Unknown deduplication strategy #{name}"
        end
      end
    end
  end
end
