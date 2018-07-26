module Projects
  module Prometheus
    module Metrics
      class UpdateService < Metrics::BaseService
        def execute
          metric.update!(params)
          schedule_alert_update if requires_alert_update?
          metric
        end

        private

        def requires_alert_update?
          has_alert? && (changing_title? || changing_query?)
        end

        def changing_title?
          metric.previous_changes.include?(:title)
        end

        def changing_query?
          metric.previous_changes.include?(:query)
        end
      end
    end
  end
end
