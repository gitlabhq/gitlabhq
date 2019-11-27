# frozen_string_literal: true

# Responsible for determining which dashboard service should
# be used to fetch or generate a dashboard hash.
# The services can be considered in two categories - embeds
# and dashboards. Embeds are all portions of dashboards.
module Gitlab
  module Metrics
    module Dashboard
      class ServiceSelector
        SERVICES = ::Metrics::Dashboard

        class << self
          include Gitlab::Utils::StrongMemoize

          # Returns a class which inherits from the BaseService
          # class that can be used to obtain a dashboard.
          # @return [Gitlab::Metrics::Dashboard::Services::BaseService]
          def call(params)
            return SERVICES::CustomMetricEmbedService if custom_metric_embed?(params)
            return SERVICES::GrafanaMetricEmbedService if grafana_metric_embed?(params)
            return SERVICES::DynamicEmbedService if dynamic_embed?(params)
            return SERVICES::DefaultEmbedService if params[:embedded]
            return SERVICES::SystemDashboardService if system_dashboard?(params[:dashboard_path])
            return SERVICES::ProjectDashboardService if params[:dashboard_path]

            default_service
          end

          private

          def default_service
            SERVICES::SystemDashboardService
          end

          def system_dashboard?(filepath)
            SERVICES::SystemDashboardService.matching_dashboard?(filepath)
          end

          def custom_metric_embed?(params)
            SERVICES::CustomMetricEmbedService.valid_params?(params)
          end

          def grafana_metric_embed?(params)
            SERVICES::GrafanaMetricEmbedService.valid_params?(params)
          end

          def dynamic_embed?(params)
            SERVICES::DynamicEmbedService.valid_params?(params)
          end
        end
      end
    end
  end
end

Gitlab::Metrics::Dashboard::ServiceSelector.prepend_if_ee('EE::Gitlab::Metrics::Dashboard::ServiceSelector')
