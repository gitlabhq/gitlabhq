# frozen_string_literal: true

# Returns DB-supplmented dashboard info for determining
# the layout of UI. Intended entry-point for the Metrics::Dashboard
# module.
module Gitlab
  module Metrics
    module Dashboard
      class Finder
        PREDEFINED_DASHBOARD_LIST = [
          ::Metrics::Dashboard::PodDashboardService,
          ::Metrics::Dashboard::SystemDashboardService
        ].freeze

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
          # @param options - cluster [Cluster]. Used by
          #         embedded and un-embedded dashboards.
          # @param options - cluster_type [Symbol] The level of
          #         cluster, one of [:admin, :project, :group]. Used by
          #         embedded and un-embedded dashboards.
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
            dashboards = user_facing_dashboard_services(project).flat_map do |service|
              service.all_dashboard_paths(project)
            end

            Gitlab::Utils.stable_sort_by(dashboards) { |dashboard| dashboard[:display_name].downcase }
          end

          private

          def user_facing_dashboard_services(project)
            predefined_dashboard_services_for(project) + [project_service]
          end

          def predefined_dashboard_services_for(project)
            # Only list the self monitoring dashboard on the self monitoring project,
            # since it is the only dashboard (at time of writing) that shows data
            # about GitLab itself.
            if project.self_monitoring?
              return [self_monitoring_service]
            end

            PREDEFINED_DASHBOARD_LIST
          end

          def system_service
            ::Metrics::Dashboard::SystemDashboardService
          end

          def project_service
            ::Metrics::Dashboard::CustomDashboardService
          end

          def self_monitoring_service
            ::Metrics::Dashboard::SelfMonitoringDashboardService
          end

          def service_for(options)
            Gitlab::Metrics::Dashboard::ServiceSelector.call(options)
          end
        end
      end
    end
  end
end
