# frozen_string_literal: true

# Fetches the system metrics dashboard and formats the output.
# Use Gitlab::Metrics::Dashboard::Finder to retrive dashboards.
module Gitlab
  module Metrics
    module Dashboard
      class SystemDashboardService < Gitlab::Metrics::Dashboard::BaseService
        SYSTEM_DASHBOARD_PATH = 'config/prometheus/common_metrics.yml'

        class << self
          def all_dashboard_paths(_project)
            [{
              path: SYSTEM_DASHBOARD_PATH,
              default: true
            }]
          end

          def system_dashboard?(filepath)
            filepath == SYSTEM_DASHBOARD_PATH
          end
        end

        private

        def dashboard_path
          SYSTEM_DASHBOARD_PATH
        end

        # Returns the base metrics shipped with every GitLab service.
        def get_raw_dashboard
          yml = File.read(Rails.root.join(dashboard_path))

          YAML.safe_load(yml)
        end

        def cache_key
          "metrics_dashboard_#{dashboard_path}"
        end

        def insert_project_metrics?
          true
        end
      end
    end
  end
end
