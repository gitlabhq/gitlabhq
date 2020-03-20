# frozen_string_literal: true

module Projects
  module Prometheus
    module Alerts
      module AlertParams
        def alert_params
          return params if params[:operator].blank?

          params.merge(
            operator: PrometheusAlert.operator_to_enum(params[:operator])
          )
        end
      end
    end
  end
end
