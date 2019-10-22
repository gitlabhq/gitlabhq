# frozen_string_literal: true

module Gitlab
  module HealthChecks
    # This check can only be run on Puma `master` process
    class PumaCheck
      extend SimpleAbstractCheck

      class << self
        private

        def metric_prefix
          'puma_check'
        end

        def successful?(result)
          result > 0
        end

        def check
          return unless defined?(::Puma)

          stats = Puma.stats
          stats = JSON.parse(stats)

          # If `workers` is missing this means that
          # Puma server is running in single mode
          stats.fetch('workers', 1)
        rescue NoMethodError
          # server is not ready
          0
        end
      end
    end
  end
end
