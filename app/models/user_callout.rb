# frozen_string_literal: true

class UserCallout < ApplicationRecord
  belongs_to :user

  enum feature_name: {
    gke_cluster_integration: 1,
    gcp_signup_offer: 2,
    cluster_security_warning: 3,
    gold_trial: 4,                    # EE-only
    geo_enable_hashed_storage: 5,     # EE-only
    geo_migrate_hashed_storage: 6,    # EE-only
    canary_deployment: 7,             # EE-only
    gold_trial_billings: 8,           # EE-only
    suggest_popover_dismissed: 9,
    tabs_position_highlight: 10,
    threat_monitoring_info: 11,         # EE-only
    account_recovery_regular_check: 12, # EE-only
    webhooks_moved: 13,
    service_templates_deprecated: 14,
    admin_integrations_moved: 15,
    web_ide_alert_dismissed: 16, # no longer in use
    active_user_count_threshold: 18,           # EE-only
    buy_pipeline_minutes_notification_dot: 19, # EE-only
    personal_access_token_expiry: 21,          # EE-only
    suggest_pipeline: 22,
    customize_homepage: 23,
    feature_flags_new_version: 24,
    registration_enabled_callout: 25,
    new_user_signups_cap_reached: 26           # EE-only
  }

  validates :user, presence: true
  validates :feature_name,
    presence: true,
    uniqueness: { scope: :user_id },
    inclusion: { in: UserCallout.feature_names.keys }

  scope :with_feature_name, -> (feature_name) { where(feature_name: UserCallout.feature_names[feature_name]) }
  scope :with_dismissed_after, -> (dismissed_after) { where('dismissed_at > ?', dismissed_after) }
end
