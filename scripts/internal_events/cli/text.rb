# frozen_string_literal: true

# Blocks of text rendered in CLI
module InternalEventsCli
  module Text
    extend Helpers

    CLI_INSTRUCTIONS = <<~TEXT.freeze
      #{format_info('INSTRUCTIONS:')}
      To start tracking usage of a feature...

        1) Define event (using CLI)
        2) Trigger event (from code)
        3) Define metric (using CLI)
        4) View data in Tableau (after merge & deploy)

      This CLI will help you create the correct defintion files, then provide code examples for instrumentation and testing.

      Learn more: https://docs.gitlab.com/ee/development/internal_analytics/#fundamental-concepts

    TEXT

    # TODO: Remove "NEW TOOL" comment after 3 months
    FEEDBACK_NOTICE = format_heading <<~TEXT.chomp
      Thanks for using the Internal Events CLI!

      Please reach out with any feedback!
        About Internal Events: https://gitlab.com/gitlab-org/analytics-section/analytics-instrumentation/internal/-/issues/687
        About CLI: https://gitlab.com/gitlab-org/gitlab/-/issues/434038
        In Slack: #g_analyze_analytics_instrumentation

      Let us know that you used the CLI! React with 👍 on the feedback issue or post in Slack!
    TEXT

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
          https://docs.gitlab.com/ee/user/product_analytics/
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

    EVENT_DESCRIPTION_INTRO = <<~TEXT.freeze
      #{format_info('EVENT DESCRIPTION')}
      Include what the event is supposed to track, where, and when.

      The description field helps others find & reuse this event. This will be used by Engineering, Product, Data team, Support -- and also GitLab customers directly. Be specific and explicit.
        ex - Debian package published to the registry using a deploy token
        ex - Issue confidentiality was changed

    TEXT

    EVENT_DESCRIPTION_HELP = <<~TEXT.freeze
      #{format_warning('Required. 10+ words likely, but length may vary.')}

      #{format_info('GOOD EXAMPLES:')}
      - Pipeline is created with a CI Template file included in its configuration
      - Quick action `/assign @user1` used to assign a single individual to an issuable
      - Quick action `/target_branch` used on a Merge Request
      - Quick actions `/unlabel` or `/remove_label` used to remove one or more specific labels
      - User edits file using the single file editor
      - User edits file using the Web IDE
      - User removed issue link between issue and incident
      - Debian package published to the registry using a deploy token

      #{format_info('GUT CHECK:')}
      For your description...
        1. Would two different engineers likely instrument the event from the same code locations?
        2. Would a new GitLab user find where the event is triggered in the product?
        3. Would a GitLab customer understand what the description says?


    TEXT

    EVENT_ACTION_INTRO = <<~TEXT.freeze
      #{format_info('EVENT NAME')}
      The event name is a unique identifier used from both a) app code and b) metric definitions.
      The name should concisely communicate the same information as the event description.

        ex - change_time_estimate_on_issue
        ex - push_package_to_repository
        ex - publish_go_module_to_the_registry_from_pipeline
        ex - admin_user_comments_on_issue_while_impersonating_blocked_user

      #{format_info('EXPECTED FORMAT:')} #{format_selection('<action>_<target_of_action>_<where/when>')}

        ex) click_save_button_in_issue_description_within_15s_of_page_load
          - ACTION: click
          - TARGET: save button
          - WHERE: in issue description
          - WHEN: within 15s of page load

    TEXT

    EVENT_ACTION_HELP = <<~TEXT.freeze
      #{format_warning('Required. Must be globally unique. Must use only letters/numbers/underscores.')}

      #{format_info('FAQs:')}
      - Q: Present tense or past tense?
        A: Prefer present tense! But it's up to you.
      - Q: Other event names have prefixes like `i_` or the `g_group_name`. Why?
        A: Those are leftovers from legacy naming schemes. Changing the names of old events/metrics can break dashboards, so stability is better than uniformity.


    TEXT

    EVENT_IDENTIFIERS_INTRO = <<~TEXT.freeze
      #{format_info('EVENT CONTEXT')}
      Identifies the attributes recorded when the event occurs. Generally, we want to include every identifier available to us when the event is triggered.

      #{format_info('BACKEND')}: Attributes must be specified when the event is triggered
        ex) User, project, and namespace are the identifiers available for backend instrumentation:
          include Gitlab::InternalEventsTracking

          track_internal_event(
            '%s',
            user: user,
            project: project,
            namespace: project.namespace
          )

      #{format_info('FRONTEND')}: Attributes are automatically included from the URL
        ex) When a user takes an action on the MR list page, the URL is https://gitlab.com/gitlab-org/gitlab/-/merge_requests
            Because this URL is for a project, we know that all of user/project/namespace are available for the event

      #{format_info('NOTE')}: If you're planning to instrument a unique-by-user metric, you should still include project & namespace when possible. This is especially helpful in the data warehouse, where namespace and project can make events relevant for CSM use-cases.

    TEXT

    DATABASE_METRIC_NOTICE = <<~TEXT

      For right now, this script can only define metrics for internal events.

      For more info on instrumenting database-backed metrics, see https://docs.gitlab.com/ee/development/internal_analytics/metrics/metrics_instrumentation.html
    TEXT

    ALL_METRICS_EXIST_NOTICE = <<~TEXT

      Looks like the potential metrics for this event either already exist or are unsupported.

      Check out https://metrics.gitlab.com/ for improved event/metric search capabilities.
    TEXT

    METRIC_DESCRIPTION_INTRO = <<~TEXT.freeze
      #{format_info('METRIC DESCRIPTION')}
      Describes which occurrences of an event are tracked in the metric and how they're grouped.

      The description field is critical for helping others find & reuse this event. This will be used by Engineering, Product, Data team, Support -- and also GitLab customers directly. Be specific and explicit.

      #{format_info('GOOD EXAMPLES:')}
      - Total count of analytics dashboard list views
      - Weekly count of unique users who viewed the analytics dashboard list
      - Monthly count of unique projects where the analytics dashboard list was viewed
      - Total count of issue updates

      #{format_info('SELECTED EVENT(S):')}
    TEXT

    METRIC_DESCRIPTION_HELP = <<~TEXT.freeze
      #{format_warning('Required. 10+ words likely, but length may vary.')}

         An event description can often be rearranged to work as a metric description.

         ex) Event description: A merge request was created
             Metric description: Total count of merge requests created
             Metric description: Weekly count of unqiue users who created merge requests

         Look at the event descriptions above to get ideas!
    TEXT
  end
end
