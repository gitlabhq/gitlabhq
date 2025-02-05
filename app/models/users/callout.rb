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
      # 28 removed in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/146309
      pipeline_needs_banner: 29,
      pipeline_needs_hover_tip: 30,
      web_ide_ci_environments_guidance: 31,
      security_configuration_upgrade_banner: 32,
      # 33 removed in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/159243
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
      ci_minutes_limit_alert_warning_stage: 44,
      ci_minutes_limit_alert_danger_stage: 45,
      ci_minutes_limit_alert_exceeded_stage: 46,
      # 47 and 48 were removed with https://gitlab.com/gitlab-org/gitlab/-/merge_requests/95446
      # 49 was removed with https://gitlab.com/gitlab-org/gitlab/-/merge_requests/91533
      # because the banner was no longer relevant.
      # Records will be migrated with https://gitlab.com/gitlab-org/gitlab/-/issues/367293
      preview_user_over_limit_free_plan_alert: 50, # EE-only
      user_reached_limit_free_plan_alert: 51, # EE-only
      submit_license_usage_data_banner: 52, # EE-only
      personal_project_limitations_banner: 53, # EE-only
      mr_experience_survey: 54,
      # 55 removed in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/121920
      namespace_storage_limit_alert_warning_threshold: 56, # EE-only
      namespace_storage_limit_alert_alert_threshold: 57, # EE-only
      namespace_storage_limit_alert_error_threshold: 58, # EE-only
      project_quality_summary_feedback: 59, # EE-only
      # 60 removed in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/154140
      new_top_level_group_alert: 61,
      # 62, removed in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131314
      # 63 and 64 were removed with https://gitlab.com/gitlab-org/gitlab/-/merge_requests/120233
      branch_rules_info_callout: 65,
      # 66 removed in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/135470/
      # 67 removed in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/121920
      project_repository_limit_alert_warning_threshold: 68, # EE-only
      # 69 removed in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/122494
      # 70 removed in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/122494
      # 71 removed in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/134432
      # 72 removed in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/129022
      namespace_over_storage_users_combined_alert: 73, # EE-only
      # 74 removed in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/132751
      vsd_feedback_banner: 75, # EE-only
      security_policy_protected_branch_modification: 76, # EE-only
      vulnerability_report_grouping: 77, # EE-only
      # 78 removed in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/161010,
      # 79 removed in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/143862
      duo_chat_callout: 80, # EE-only
      # 81 removed in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/146322
      product_analytics_dashboard_feedback: 82, # EE-only
      joining_a_project_alert: 83, # EE-only
      transition_to_jihu_callout: 84,
      # 85 removed in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169248
      # 86 removed in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/152619
      deployment_details_feedback: 87,
      # 88 removed in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/152999
      # 89 removed in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/152981
      deployment_approvals_empty_state: 90,
      period_in_terraform_state_name_alert: 91,
      work_item_epic_feedback: 92, # EE-only
      branch_rules_tip_callout: 93,
      openssl_callout: 94,
      # 95 removed in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/170868
      new_mr_dashboard_banner: 96,
      planner_role_callout: 97,
      # EE-only
      pipl_compliance_alert: 98,
      new_merge_request_dashboard_welcome: 99
    }

    validates :feature_name,
      presence: true,
      uniqueness: { scope: :user_id },
      inclusion: { in: Users::Callout.feature_names.keys }

    scope :with_feature_name, ->(feature_name) { where(feature_name: feature_name) }
  end
end
