# frozen_string_literal: true

module Import
  module AfterExportStrategies
    class AfterExportStrategyBuilder
      StrategyNotFoundError = Class.new(StandardError)

      def self.build!(strategy_klass, attributes = {})
        return default_strategy.new unless strategy_klass

        attributes ||= {}
        klass = begin
          strategy_klass.constantize
        rescue StandardError
          nil
        end

        unless klass && klass < BaseAfterExportStrategy
          raise StrategyNotFoundError, "Strategy #{strategy_klass} not found"
        end

        klass.new(**attributes.symbolize_keys)
      end

      def self.default_strategy
        DownloadNotificationStrategy
      end
    end
  end
end
