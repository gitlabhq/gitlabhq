# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module PauseControl
      DEFAULT_STRATEGY = :none

      UnknownStrategyError = Class.new(StandardError)

      STRATEGIES = {
        zoekt: ::Gitlab::SidekiqMiddleware::PauseControl::Strategies::Zoekt,
        none: ::Gitlab::SidekiqMiddleware::PauseControl::Strategies::None
      }.freeze

      def self.for(name)
        STRATEGIES.fetch(name, STRATEGIES[DEFAULT_STRATEGY])
      end
    end
  end
end
