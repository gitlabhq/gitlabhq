# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class IssuesCreatedFromAlertsMetric < NumbersMetric
          ISSUES_FROM_ALERTS_METRICS = [
            IssuesWithAlertManagementAlertsMetric,
            IssuesWithPrometheusAlertEvents
          ].freeze

          operation :add

          data do |time_frame|
            ISSUES_FROM_ALERTS_METRICS.map { |metric| metric.new(time_frame: time_frame).value }
          end

          # overwriting instrumentation to generate the appropriate sql query
          def instrumentation
            'SELECT ' + ISSUES_FROM_ALERTS_METRICS.map do |metric|
              "(#{metric.new(time_frame: time_frame).instrumentation})"
            end.join(' + ')
          end
        end
      end
    end
  end
end
