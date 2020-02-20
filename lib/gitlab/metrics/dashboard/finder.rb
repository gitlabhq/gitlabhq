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
          # @param options [Hash<Symbol,Any>]
          # @param options - embedded [Boolean] Determines whether the
          #         dashboard is to be rendered as part of an
          #         issue or location other than the primary
          #         metrics dashboard UI. Returns only the
          #         Memory/CPU charts of the system dash.
          # @param options - dashboard_path [String] Path at which the
          #         dashboard can be found. Nil values will
          #         default to the system dashboard.
          # @param options - group [String, Group] Title of the group
          #         to which a panel might belong. Used by
          #         embedded dashboards. If cluster dashboard,
          #         refers to the Group corresponding to the cluster.
          # @param options - title [String] Title of the panel.
          #         Used by embedded dashboards.
          # @param options - y_label [String] Y-Axis label of
          #         a panel. Used by embedded dashboards.
          # @param options - cluster [Cluster]
          # @param options - cluster_type [Symbol] The level of
          #         cluster, one of [:admin, :project, :group]
          # @param options - grafana_url [String] URL pointing
          #         to a grafana dashboard panel
          # @param options - prometheus_alert_id [Integer] ID of
          #         a PrometheusAlert. For dashboard embeds.
          # @return [Hash]
          def find(project, user, options = {})
            service_for(options)
              .new(project, user, options)
              .get_dashboard
          end

          # Returns a dashboard without any supplemental info.
          # Returns only full, yml-defined dashboards.
          # @return [Hash]
          def find_raw(project, dashboard_path: nil)
            service_for(dashboard_path: dashboard_path)
              .new(project, nil, dashboard_path: dashboard_path)
              .raw_dashboard
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

            default_dashboard_path(project)
            .+ project_service.all_dashboard_paths(project)
          end

          private

          def system_service
            ::Metrics::Dashboard::SystemDashboardService
          end

          def project_service
            ::Metrics::Dashboard::ProjectDashboardService
          end

          def self_monitoring_service
            ::Metrics::Dashboard::SelfMonitoringDashboardService
          end

          def default_dashboard_path(project)
            if project.self_monitoring?
              self_monitoring_service.all_dashboard_paths(project)
            else
              system_service.all_dashboard_paths(project)
            end
          end

          def service_for(options)
            Gitlab::Metrics::Dashboard::ServiceSelector.call(options)
          end
        end
      end
    end
  end
end
