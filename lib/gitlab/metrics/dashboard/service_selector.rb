# frozen_string_literal: true

# Responsible for determining which dashboard service should
# be used to fetch or generate a dashboard hash.
# The services can be considered in two categories - embeds
# and dashboards. Embeds are all portions of dashboards.
module Gitlab
  module Metrics
    module Dashboard
      class ServiceSelector
        class << self
          include Gitlab::Utils::StrongMemoize

          SERVICES = [
            ::Metrics::Dashboard::CustomMetricEmbedService,
            ::Metrics::Dashboard::GrafanaMetricEmbedService,
            ::Metrics::Dashboard::DynamicEmbedService,
            ::Metrics::Dashboard::DefaultEmbedService,
            ::Metrics::Dashboard::SystemDashboardService,
            ::Metrics::Dashboard::PodDashboardService,
            ::Metrics::Dashboard::ProjectDashboardService
          ].freeze

          # Returns a class which inherits from the BaseService
          # class that can be used to obtain a dashboard for
          # the provided params.
          # @return [Gitlab::Metrics::Dashboard::Services::BaseService]
          def call(params)
            service = services.find do |service_class|
              service_class.valid_params?(params)
            end

            service || default_service
          end

          private

          def services
            SERVICES
          end

          def default_service
            ::Metrics::Dashboard::SystemDashboardService
          end
        end
      end
    end
  end
end

Gitlab::Metrics::Dashboard::ServiceSelector.prepend_if_ee('EE::Gitlab::Metrics::Dashboard::ServiceSelector')
