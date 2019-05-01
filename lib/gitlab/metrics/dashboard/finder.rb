# frozen_string_literal: true

# Returns DB-supplmented dashboard info for determining
# the layout of UI. Intended entry-point for the Metrics::Dashboard
# module.
module Gitlab
  module Metrics
    module Dashboard
      class Finder
        class << self
          # Returns a formatted dashboard packed with DB info.
          # @return [Hash]
          def find(project, user, environment, dashboard_path = nil)
            service = system_dashboard?(dashboard_path) ? system_service : project_service

            service
              .new(project, user, environment: environment, dashboard_path: dashboard_path)
              .get_dashboard
          end

          # Summary of all known dashboards.
          # @return [Array<Hash>] ex) [{ path: String, default: Boolean }]
          def find_all_paths(project)
            project.repository.metrics_dashboard_paths
          end

          # Summary of all known dashboards. Used to populate repo cache.
          # Prefer #find_all_paths.
          def find_all_paths_from_source(project)
            system_service.all_dashboard_paths(project)
            .+ project_service.all_dashboard_paths(project)
          end

          private

          def system_service
            Gitlab::Metrics::Dashboard::SystemDashboardService
          end

          def project_service
            Gitlab::Metrics::Dashboard::ProjectDashboardService
          end

          def system_dashboard?(filepath)
            !filepath || system_service.system_dashboard?(filepath)
          end
        end
      end
    end
  end
end
