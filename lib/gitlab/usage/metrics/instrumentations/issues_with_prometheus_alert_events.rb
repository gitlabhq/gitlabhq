# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class IssuesWithPrometheusAlertEvents < DatabaseMetric
          # this metric is used in IssuesCreatedFromAlertsMetric
          # do not report metric directly in service ping
          available? { false }

          operation :count

          start { Issue.minimum(:id) }
          finish { Issue.maximum(:id) }

          relation { Issue.with_prometheus_alert_events }

          cache_start_and_finish_as :issue
        end
      end
    end
  end
end
