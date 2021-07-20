# frozen_string_literal: true

module UserCalloutsHelper
  GKE_CLUSTER_INTEGRATION = 'gke_cluster_integration'
  GCP_SIGNUP_OFFER = 'gcp_signup_offer'
  SUGGEST_POPOVER_DISMISSED = 'suggest_popover_dismissed'
  SERVICE_TEMPLATES_DEPRECATED_CALLOUT = 'service_templates_deprecated_callout'
  TABS_POSITION_HIGHLIGHT = 'tabs_position_highlight'
  CUSTOMIZE_HOMEPAGE = 'customize_homepage'
  FEATURE_FLAGS_NEW_VERSION = 'feature_flags_new_version'
  REGISTRATION_ENABLED_CALLOUT = 'registration_enabled_callout'
  UNFINISHED_TAG_CLEANUP_CALLOUT = 'unfinished_tag_cleanup_callout'

  def show_gke_cluster_integration_callout?(project)
    active_nav_link?(controller: sidebar_operations_paths) &&
      can?(current_user, :create_cluster, project) &&
      !user_dismissed?(GKE_CLUSTER_INTEGRATION)
  end

  def show_gcp_signup_offer?
    !user_dismissed?(GCP_SIGNUP_OFFER)
  end

  def render_flash_user_callout(flash_type, message, feature_name)
    render 'shared/flash_user_callout', flash_type: flash_type, message: message, feature_name: feature_name
  end

  def render_dashboard_ultimate_trial(user)
  end

  def render_account_recovery_regular_check
  end

  def show_suggest_popover?
    !user_dismissed?(SUGGEST_POPOVER_DISMISSED)
  end

  def show_service_templates_deprecated_callout?
    !Gitlab.com? &&
    current_user&.admin? &&
    Integration.for_template.active.exists? &&
    !user_dismissed?(SERVICE_TEMPLATES_DEPRECATED_CALLOUT)
  end

  def show_customize_homepage_banner?
    current_user.default_dashboard? && !user_dismissed?(CUSTOMIZE_HOMEPAGE)
  end

  def show_feature_flags_new_version?
    !user_dismissed?(FEATURE_FLAGS_NEW_VERSION)
  end

  def show_unfinished_tag_cleanup_callout?
    !user_dismissed?(UNFINISHED_TAG_CLEANUP_CALLOUT)
  end

  def show_registration_enabled_user_callout?
    !Gitlab.com? &&
    current_user&.admin? &&
    signup_enabled? &&
    !user_dismissed?(REGISTRATION_ENABLED_CALLOUT)
  end

  private

  def user_dismissed?(feature_name, ignore_dismissal_earlier_than = nil)
    return false unless current_user

    current_user.dismissed_callout?(feature_name: feature_name, ignore_dismissal_earlier_than: ignore_dismissal_earlier_than)
  end
end

UserCalloutsHelper.prepend_mod_with('UserCalloutsHelper')
