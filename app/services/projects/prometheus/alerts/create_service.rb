# frozen_string_literal: true

module Projects
  module Prometheus
    module Alerts
      class CreateService < BaseProjectService
        include AlertParams

        def execute
          project.prometheus_alerts.create(alert_params)
        end
      end
    end
  end
end
