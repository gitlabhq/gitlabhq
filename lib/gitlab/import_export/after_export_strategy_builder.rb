# frozen_string_literal: true

module Gitlab
  module ImportExport
    class AfterExportStrategyBuilder
      StrategyNotFoundError = Class.new(StandardError)

      def self.build!(strategy_klass, attributes = {})
        return default_strategy.new unless strategy_klass

        attributes ||= {}
        klass = strategy_klass.constantize rescue nil

        unless klass && klass < AfterExportStrategies::BaseAfterExportStrategy
          raise StrategyNotFoundError, "Strategy #{strategy_klass} not found"
        end

        klass.new(**attributes.symbolize_keys)
      end

      def self.default_strategy
        AfterExportStrategies::DownloadNotificationStrategy
      end
    end
  end
end
