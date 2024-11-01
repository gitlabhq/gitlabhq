# frozen_string_literal: true

# Blocks of text rendered in CLI
module InternalEventsCli
  module Text
    module FlowAdvisor
      extend Helpers

      ALTERNATE_RESOURCES_NOTICE = <<~TEXT.freeze
        Other resources:

        #{format_warning('Tracking GitLab feature usage from database info:')}
            https://docs.gitlab.com/ee/development/internal_analytics/metrics/metrics_instrumentation.html#database-metrics

        #{format_warning('Migrating existing metrics to use Internal Events:')}
            https://docs.gitlab.com/ee/development/internal_analytics/internal_event_instrumentation/migration.html

        #{format_warning('Remove an existing metric:')}
            https://docs.gitlab.com/ee/development/internal_analytics/metrics/metrics_lifecycle.html

        #{format_warning('Finding existing usage data for GitLab features:')}
            https://metrics.gitlab.com/ (Customize Table > Snowflake query)
            https://10az.online.tableau.com/#/site/gitlab/views/SnowplowEventExplorationLast30Days/SnowplowEventExplorationLast30D
            https://10az.online.tableau.com/#/site/gitlab/views/PDServicePingExplorationDashboard/MetricsExploration

        #{format_warning('Customer wants usage data for their own GitLab instance:')}
            https://docs.gitlab.com/ee/user/analytics/

        #{format_warning('Customer wants usage data for their own products:')}
            https://docs.gitlab.com/ee/operations/product_analytics/
      TEXT

      EVENT_TRACKING_EXAMPLES = <<~TEXT
        Product usage can be tracked in several ways.

        By tracking events:     ex) a user changes the assignee on an issue
                                ex) a user uploads a CI template
                                ex) a service desk request is received
                                ex) all stale runners are cleaned up
                                ex) a user copies code to the clipboard from markdown
                                ex) a user uploads an issue template OR a user uploads an MR template

        From database data:     ex) track whether each gitlab instance allows signups
                                ex) query how many projects are on each gitlab instance

      TEXT

      EVENT_EXISTENCE_CHECK_INSTRUCTIONS = <<~TEXT.freeze
        To determine what to do next, let's figure out if the event is already tracked & usable.

        If you're unsure whether an event exists, you can check the existing defintions.

          #{format_info('FROM GDK')}: Check `config/events/` or `ee/config/events`
          #{format_info('FROM BROWSER')}: Check https://metrics.gitlab.com/snowplow

          Find one? Create a new metric for the event.
          Otherwise? Create a new event.

        If you find a relevant event that does not have the property `internal_events: true`, it can be migrated to
        Internal Events. See https://docs.gitlab.com/ee/development/internal_analytics/internal_event_instrumentation/migration.html

      TEXT
    end
  end
end
