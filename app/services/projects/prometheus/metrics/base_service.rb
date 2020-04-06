# frozen_string_literal: true

module Projects
  module Prometheus
    module Metrics
      class BaseService
        include Gitlab::Utils::StrongMemoize

        def initialize(metric, params = {})
          @metric = metric
          @project = metric.project
          @params = params.dup
        end

        protected

        attr_reader :metric, :project, :params

        def application
          alert.environment.cluster_prometheus_adapter
        end

        def schedule_alert_update
          return unless alert
          return unless alert.environment

          ::Clusters::Applications::ScheduleUpdateService.new(
            alert.environment.cluster_prometheus_adapter, project).execute
        end

        def alert
          strong_memoize(:alert) { find_alert(metric) }
        end

        def find_alert(metric)
          Projects::Prometheus::AlertsFinder
            .new(project: project, metric: metric)
            .execute
            .first
        end

        def has_alert?
          alert.present?
        end
      end
    end
  end
end
