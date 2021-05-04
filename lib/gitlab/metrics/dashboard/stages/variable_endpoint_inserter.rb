# frozen_string_literal: true

module Gitlab
  module Metrics
    module Dashboard
      module Stages
        class VariableEndpointInserter < BaseStage
          VARIABLE_TYPE_METRIC_LABEL_VALUES = 'metric_label_values'

          def transform!
            raise Errors::DashboardProcessingError, _('Environment is required for Stages::VariableEndpointInserter') unless params[:environment]

            for_variables do |variable_name, variable|
              if variable.is_a?(Hash) && variable[:type] == VARIABLE_TYPE_METRIC_LABEL_VALUES
                variable[:options][:prometheus_endpoint_path] = endpoint_for_variable(variable.dig(:options, :series_selector))
              end
            end
          end

          private

          def endpoint_for_variable(series_selector)
            Gitlab::Routing.url_helpers.prometheus_api_project_environment_path(
              project,
              params[:environment],
              proxy_path: ::Prometheus::ProxyService::PROMETHEUS_SERIES_API,
              match: Array(series_selector)
            )
          end
        end
      end
    end
  end
end
