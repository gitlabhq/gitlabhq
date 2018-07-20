module Projects
  module Prometheus
    module Metrics
      class BaseService
        def initialize(metric, params = {})
          @metric = metric
          @project = metric.project
          @params = params.dup
        end

        protected

        attr_reader :metric, :project, :params

        def application
          metric.prometheus_alert.environment.cluster_prometheus_adapter
        end

        def schedule_alert_update
          ::Clusters::Applications::ScheduleUpdateService.new(application, project).execute
        end

        def has_alert?
          metric.prometheus_alert.present?
        end
      end
    end
  end
end
