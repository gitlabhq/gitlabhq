# frozen_string_literal: true

module Projects
  module Prometheus
    module Metrics
      class DestroyService < Metrics::BaseService
        def execute
          schedule_alert_update if has_alert?
          metric.destroy
        end
      end
    end
  end
end
