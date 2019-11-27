# frozen_string_literal: true

module Metrics
  module Dashboard
    class PredefinedDashboardService < ::Metrics::Dashboard::BaseService
      # These constants should be overridden in the inheriting class. For Ex:
      # DASHBOARD_PATH = 'config/prometheus/common_metrics.yml'
      # DASHBOARD_NAME = 'Default'
      DASHBOARD_PATH = nil
      DASHBOARD_NAME = nil

      SEQUENCE = [
        STAGES::EndpointInserter,
        STAGES::Sorter
      ].freeze

      class << self
        def matching_dashboard?(filepath)
          filepath == self::DASHBOARD_PATH
        end
      end

      private

      def cache_key
        "metrics_dashboard_#{dashboard_path}"
      end

      def dashboard_path
        self.class::DASHBOARD_PATH
      end

      # Returns the base metrics shipped with every GitLab service.
      def get_raw_dashboard
        yml = File.read(Rails.root.join(dashboard_path))

        YAML.safe_load(yml)
      end

      def sequence
        self.class::SEQUENCE
      end
    end
  end
end
