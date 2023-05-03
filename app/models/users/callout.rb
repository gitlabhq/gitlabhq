# frozen_string_literal: true

module Users
  class Callout < ApplicationRecord
    include Users::Calloutable

    self.table_name = 'user_callouts'

    enum feature_name: {
      gke_cluster_integration: 1,
      gcp_signup_offer: 2,
      cluster_security_warning: 3,
      ultimate_trial: 4,                         # EE-only
      geo_enable_hashed_storage: 5,              # EE-only
      geo_migrate_hashed_storage: 6,             # EE-only
      canary_deployment: 7,                      # EE-only
      gold_trial_billings: 8,                    # EE-only
      suggest_popover_dismissed: 9,
      tabs_position_highlight: 10,
      threat_monitoring_info: 11,                # EE-only
      two_factor_auth_recovery_settings_check: 12, # EE-only
      web_ide_alert_dismissed: 16,               # no longer in use
      active_user_count_threshold: 18,           # EE-only
      buy_pipeline_minutes_notification_dot: 19, # EE-only
      personal_access_token_expiry: 21,          # EE-only
      suggest_pipeline: 22,
      feature_flags_new_version: 24,
      registration_enabled_callout: 25,
      new_user_signups_cap_reached: 26,          # EE-only
      unfinished_tag_cleanup_callout: 27,
      eoa_bronze_plan_banner: 28,                # EE-only
      pipeline_needs_banner: 29,
      pipeline_needs_hover_tip: 30,
      web_ide_ci_environments_guidance: 31,
      security_configuration_upgrade_banner: 32,
      cloud_licensing_subscription_activation_banner: 33, # EE-only
      trial_status_reminder_d14: 34,             # EE-only
      trial_status_reminder_d3: 35,              # EE-only
      security_configuration_devops_alert: 36,   # EE-only
      profile_personal_access_token_expiry: 37,  # EE-only
      terraform_notification_dismissed: 38,
      security_newsletter_callout: 39,
      verification_reminder: 40, # EE-only
      ci_deprecation_warning_for_types_keyword: 41,
      security_training_feature_promotion: 42, # EE-only
      namespace_storage_pre_enforcement_banner: 43, # EE-only
      # 44, 45, 46 were unused and removed with https://gitlab.com/gitlab-org/gitlab/-/merge_requests/118330,
      # they can be replaced.
      # 47 and 48 were removed with https://gitlab.com/gitlab-org/gitlab/-/merge_requests/95446
      # 49 was removed with https://gitlab.com/gitlab-org/gitlab/-/merge_requests/91533
      # because the banner was no longer relevant.
      # Records will be migrated with https://gitlab.com/gitlab-org/gitlab/-/issues/367293
      preview_user_over_limit_free_plan_alert: 50, # EE-only
      user_reached_limit_free_plan_alert: 51, # EE-only
      submit_license_usage_data_banner: 52, # EE-only
      personal_project_limitations_banner: 53, # EE-only
      mr_experience_survey: 54,
      namespace_storage_limit_banner_info_threshold: 55, # EE-only
      namespace_storage_limit_banner_warning_threshold: 56, # EE-only
      namespace_storage_limit_banner_alert_threshold: 57, # EE-only
      namespace_storage_limit_banner_error_threshold: 58, # EE-only
      project_quality_summary_feedback: 59,       # EE-only
      merge_request_settings_moved_callout: 60,
      new_top_level_group_alert: 61,
      artifacts_management_page_feedback_banner: 62,
      vscode_web_ide: 63,
      vscode_web_ide_callout: 64,
      branch_rules_info_callout: 65,
      create_runner_workflow_banner: 66
    }

    validates :feature_name,
      presence: true,
      uniqueness: { scope: :user_id },
      inclusion: { in: Users::Callout.feature_names.keys }

    scope :with_feature_name, -> (feature_name) { where(feature_name: feature_name) }
  end
end
