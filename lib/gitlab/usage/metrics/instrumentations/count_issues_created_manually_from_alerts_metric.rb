# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountIssuesCreatedManuallyFromAlertsMetric < DatabaseMetric
          operation :count

          start { Issue.minimum(:id) }
          finish { Issue.maximum(:id) }

          cache_start_and_finish_as :issue

          relation do
            Issue.with_alert_management_alerts.not_authored_by(::Users::Internal.alert_bot)
          end

          def value
            return FALLBACK if Gitlab.com?

            super
          end
        end
      end
    end
  end
end
