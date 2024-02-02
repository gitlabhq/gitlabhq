# frozen_string_literal: true

module Users
  module CalloutsHelper
    GKE_CLUSTER_INTEGRATION = 'gke_cluster_integration'
    GCP_SIGNUP_OFFER = 'gcp_signup_offer'
    SUGGEST_POPOVER_DISMISSED = 'suggest_popover_dismissed'
    TABS_POSITION_HIGHLIGHT = 'tabs_position_highlight'
    FEATURE_FLAGS_NEW_VERSION = 'feature_flags_new_version'
    REGISTRATION_ENABLED_CALLOUT = 'registration_enabled_callout'
    UNFINISHED_TAG_CLEANUP_CALLOUT = 'unfinished_tag_cleanup_callout'
    SECURITY_NEWSLETTER_CALLOUT = 'security_newsletter_callout'
    MERGE_REQUEST_SETTINGS_MOVED_CALLOUT = 'merge_request_settings_moved_callout'
    PAGES_MOVED_CALLOUT = 'pages_moved_callout'
    REGISTRATION_ENABLED_CALLOUT_ALLOWED_CONTROLLER_PATHS = [/^root/, /^dashboard\S*/, /^admin\S*/].freeze
    WEB_HOOK_DISABLED = 'web_hook_disabled'
    BRANCH_RULES_INFO_CALLOUT = 'branch_rules_info_callout'
    NEW_NAV_FOR_EVERYONE_CALLOUT = 'new_nav_for_everyone_callout'
    TRANSITION_TO_JIHU_CALLOUT = 'transition_to_jihu_callout'

    def show_gke_cluster_integration_callout?(project)
      active_nav_link?(controller: sidebar_operations_paths) &&
        can?(current_user, :create_cluster, project) &&
        !user_dismissed?(GKE_CLUSTER_INTEGRATION)
    end

    def show_gcp_signup_offer?
      !user_dismissed?(GCP_SIGNUP_OFFER)
    end

    def render_dashboard_ultimate_trial(user)
    end

    def render_two_factor_auth_recovery_settings_check
    end

    def show_suggest_popover?
      !user_dismissed?(SUGGEST_POPOVER_DISMISSED)
    end

    def show_feature_flags_new_version?
      !user_dismissed?(FEATURE_FLAGS_NEW_VERSION)
    end

    def show_unfinished_tag_cleanup_callout?
      !user_dismissed?(UNFINISHED_TAG_CLEANUP_CALLOUT)
    end

    def show_registration_enabled_user_callout?
      !Gitlab.com? &&
        current_user&.can_admin_all_resources? &&
        signup_enabled? &&
        !user_dismissed?(REGISTRATION_ENABLED_CALLOUT) &&
        REGISTRATION_ENABLED_CALLOUT_ALLOWED_CONTROLLER_PATHS.any? { |path| controller.controller_path.match?(path) }
    end

    def dismiss_two_factor_auth_recovery_settings_check
    end

    def show_security_newsletter_user_callout?
      current_user&.can_admin_all_resources? &&
        !user_dismissed?(SECURITY_NEWSLETTER_CALLOUT)
    end

    def web_hook_disabled_dismissed?(object)
      return false unless object.is_a?(::WebHooks::HasWebHooks)

      user_dismissed?(WEB_HOOK_DISABLED, object.last_webhook_failure, object: object)
    end

    def show_merge_request_settings_callout?(project)
      !user_dismissed?(MERGE_REQUEST_SETTINGS_MOVED_CALLOUT) && project.merge_requests_enabled?
    end

    def show_branch_rules_info?
      !user_dismissed?(BRANCH_RULES_INFO_CALLOUT)
    end

    def show_new_nav_for_everyone_callout?
      # The use_new_navigation user preference was controlled by the now removed "New navigation" toggle in the UI.
      # We want to show this banner only to signed-in users who chose to disable the new nav (`false`).
      # We don't want to show it for users who never touched the toggle and already had the new nav by default (`nil`)
      user_had_new_nav_off = current_user && current_user.use_new_navigation == false
      user_had_new_nav_off && !user_dismissed?(NEW_NAV_FOR_EVERYONE_CALLOUT)
    end

    def show_transition_to_jihu_callout?
      !Gitlab.jh? &&
        current_user&.can_admin_all_resources? &&
        %w[Asia/Hong_Kong Asia/Shanghai Asia/Macau Asia/Chongqing].include?(current_user.timezone) &&
        !user_dismissed?(TRANSITION_TO_JIHU_CALLOUT)
    end

    private

    def user_dismissed?(feature_name, ignore_dismissal_earlier_than = nil, object: nil)
      return false unless current_user

      query = { feature_name: feature_name, ignore_dismissal_earlier_than: ignore_dismissal_earlier_than }

      if object
        dismissed_callout?(object, query)
      else
        current_user.dismissed_callout?(**query)
      end
    end

    def dismissed_callout?(object, query)
      current_user.dismissed_callout_for_project?(project: object, **query)
    end
  end
end

Users::CalloutsHelper.prepend_mod
