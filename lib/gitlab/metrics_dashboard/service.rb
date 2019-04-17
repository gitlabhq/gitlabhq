# frozen_string_literal: true

# Fetches the metrics dashboard layout and supplemented the output with DB info.
module Gitlab
  module MetricsDashboard
    class Service < ::BaseService
      SYSTEM_DASHBOARD_NAME = 'common_metrics'
      SYSTEM_DASHBOARD_PATH = Rails.root.join('config', 'prometheus', "#{SYSTEM_DASHBOARD_NAME}.yml")

      # Returns a DB-supplemented json representation of a dashboard config file.
      def get_dashboard
        dashboard_string = Rails.cache.fetch(cache_key) { system_dashboard }

        dashboard = process_dashboard(dashboard_string)

        success(dashboard: dashboard)
      end

      private

      # Returns the base metrics shipped with every GitLab service.
      def system_dashboard
        YAML.load_file(SYSTEM_DASHBOARD_PATH)
      end

      def cache_key
        "metrics_dashboard_#{SYSTEM_DASHBOARD_NAME}"
      end

      def process_dashboard(dashboard)
        Processor.new(dashboard, project, params[:environment]).process
      end
    end
  end
end
