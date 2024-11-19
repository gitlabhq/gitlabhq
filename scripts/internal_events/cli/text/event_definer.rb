# frozen_string_literal: true

module InternalEventsCli
  module Text
    module EventDefiner
      extend Helpers

      DESCRIPTION_INTRO = <<~TEXT.freeze
        #{format_info('EVENT DESCRIPTION')}
        Include what the event is supposed to track, where, and when.

        The description field helps others find & reuse this event. This will be used by Engineering, Product, Data team, Support -- and also GitLab customers directly. Be specific and explicit.
          ex - Debian package published to the registry using a deploy token
          ex - Issue confidentiality was changed

      TEXT

      DESCRIPTION_HELP = <<~TEXT.freeze
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

      ACTION_INTRO = <<~TEXT.freeze
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

      ACTION_HELP = <<~TEXT.freeze
        #{format_warning('Required. Must be globally unique. Must use only letters/numbers/underscores.')}

        #{format_info('FAQs:')}
        - Q: Present tense or past tense?
          A: Prefer present tense! But it's up to you.
        - Q: Other event names have prefixes like `i_` or the `g_group_name`. Why?
          A: Those are leftovers from legacy naming schemes. Changing the names of old events/metrics can break dashboards, so stability is better than uniformity.


      TEXT

      IDENTIFIERS_INTRO = <<~TEXT.freeze
        #{format_info('KEY IDENTIFIERS')}
        Indicates the attributes recorded when the event occurs. Generally, we want to include every identifier available to us when the event is triggered.

        #{format_info('BACKEND')}: Attributes must be specified when the event is triggered
          ex) User, project, and namespace are the identifiers available for backend instrumentation:
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

      IDENTIFIER_OPTIONS = {
        %w[project namespace user] =>
          'Use case: For project-level user actions (ex - issue_assignee_changed) [MOST COMMON]',
        %w[namespace user] =>
          'Use case: For namespace-level user actions (ex - epic_assigned_to_milestone)',
        %w[user] =>
          'Use case: For user-only actions (ex - admin_impersonated_user)',
        %w[project namespace] =>
          'Use case: For project-level events without user interaction (ex - service_desk_request_received)',
        %w[namespace] =>
          'Use case: For namespace-level events without user interaction (ex - stale_runners_cleaned_up)',
        %w[feature_enabled_by_namespace_ids user] =>
          'Use case: For user actions attributable to multiple namespaces (ex - Code-Suggestions / Duo Pro)',
        %w[] =>
          'Use case: For instance-level events without user interaction [LEAST COMMON]'
      }.freeze

      ADDITIONAL_PROPERTIES_INTRO = <<~TEXT.freeze
        #{format_info('ADDITIONAL PROPERTIES')}
        Describe any related attributes or information which should be tracked when the event occurs. This enables extra capabilities:
          - Service Ping: define metrics filtered to a specific subset of events (built-in properties only)
          - Snowflake: view/sort/group individual events from GitLab.com

        BUILT-IN PROPERTIES (recommended)
        For the best performance and flexibility, provide event context using:

          property (string),  label (string),  value (numeric)

        These attribute names correspond to repurposed fields in Snowflake. They have no special meaning other than data type.

        ex) To add a metric like "Monthly count of unique users who changed an MR status to closed" using a 'change_merge_request_status' event, define an additional property like:
          Attribute: label (string)
          Description: Status of merge request after update (one of opened, merged, closed)

        CUSTOM PROPERTIES (as-needed)
        When the built-in properties are insufficient, properties of any name can be provided.
        This option becomes available after both property and label are defined, or after value is defined.

      TEXT

      ADDITIONAL_PROPERTIES_ADD_MORE_HELP = <<~TEXT.freeze
        #{format_warning('Required. Must be unique within the event context. Must use only letters/numbers/underscores.')}

        #{format_info('It should not be named any of the following:')}
        - property#{' '}
        - label
        - value

      TEXT
    end
  end
end
