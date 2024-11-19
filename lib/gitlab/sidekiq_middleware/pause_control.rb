# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    module PauseControl
      DEFAULT_STRATEGY = :none

      UnknownStrategyError = Class.new(StandardError)

      STRATEGIES = {
        click_house_migration: ::Gitlab::SidekiqMiddleware::PauseControl::Strategies::ClickHouseMigration,
        zoekt: ::Gitlab::SidekiqMiddleware::PauseControl::Strategies::Zoekt,
        none: ::Gitlab::SidekiqMiddleware::PauseControl::Strategies::None,
        advanced_search: ::Gitlab::SidekiqMiddleware::PauseControl::Strategies::AdvancedSearch,
        deprecated: ::Gitlab::SidekiqMiddleware::PauseControl::Strategies::Deprecated
      }.freeze

      def self.for(name)
        STRATEGIES.fetch(name, STRATEGIES[DEFAULT_STRATEGY])
      end
    end
  end
end
