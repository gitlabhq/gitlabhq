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
          # @param project [Project]
          # @param user [User]
          # @param environment [Environment]
          # @param opts - dashboard_path [String] Path at which the
          #         dashboard can be found. Nil values will
          #         default to the system dashboard.
          # @param opts - embedded [Boolean] Determines whether the
          #         dashboard is to be rendered as part of an
          #         issue or location other than the primary
          #         metrics dashboard UI. Returns only the
          #         Memory/CPU charts of the system dash.
          # @return [Hash]
          def find(project, user, environment, dashboard_path: nil, embedded: false)
            service_for_path(dashboard_path, embedded: embedded)
              .new(project, user, environment: environment, dashboard_path: dashboard_path)
              .get_dashboard
          end

          # Summary of all known dashboards.
          # @return [Array<Hash>] ex) [{ path: String,
          #                              display_name: String,
          #                              default: Boolean }]
          def find_all_paths(project)
            project.repository.metrics_dashboard_paths
          end

          # Summary of all known dashboards. Used to populate repo cache.
          # Prefer #find_all_paths.
          def find_all_paths_from_source(project)
            Gitlab::Metrics::Dashboard::Cache.delete_all!

            system_service.all_dashboard_paths(project)
            .+ project_service.all_dashboard_paths(project)
          end

          private

          def service_for_path(dashboard_path, embedded:)
            return embed_service if embedded
            return system_service if system_dashboard?(dashboard_path)

            project_service
          end

          def system_service
            ::Metrics::Dashboard::SystemDashboardService
          end

          def project_service
            ::Metrics::Dashboard::ProjectDashboardService
          end

          def embed_service
            ::Metrics::Dashboard::DefaultEmbedService
          end

          def system_dashboard?(filepath)
            !filepath || system_service.system_dashboard?(filepath)
          end
        end
      end
    end
  end
end
