# frozen_string_literal: true

module Metrics
  # Update metrics regarding GitLab instance wide
  #
  # Anything that is not specific to a machine, process, request or any other context
  # can be updated from this services.
  #
  # Examples of metrics that qualify:
  # * Global counters (instance users, instance projects...)
  # * State of settings stored in the database (whether a feature is active or not, tuning values...)
  #
  class GlobalMetricsUpdateService
    def execute
      return unless ::Gitlab::Metrics.prometheus_metrics_enabled?

      maintenance_mode_metric.set({}, (::Gitlab.maintenance_mode? ? 1 : 0))
    end

    def maintenance_mode_metric
      ::Gitlab::Metrics.gauge(:gitlab_maintenance_mode, 'Is GitLab Maintenance Mode enabled?')
    end
  end
end
