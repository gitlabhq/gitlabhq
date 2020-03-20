# frozen_string_literal: true

module Projects
  module Prometheus
    module Alerts
      class UpdateService < BaseService
        include AlertParams

        def execute(alert)
          alert.update(alert_params)
        end
      end
    end
  end
end
