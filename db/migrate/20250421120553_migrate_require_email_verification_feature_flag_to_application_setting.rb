# frozen_string_literal: true

class MigrateRequireEmailVerificationFeatureFlagToApplicationSetting < Gitlab::Database::Migration[2.2]
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '18.1'

  def up
    up_migrate_to_jsonb_setting(feature_flag_name: :require_email_verification,
      setting_name: :require_email_verification_on_account_locked,
      jsonb_column_name: :anti_abuse_settings,
      default_enabled: false)
  end

  def down
    down_migrate_to_jsonb_setting(setting_name: :require_email_verification_on_account_locked,
      jsonb_column_name: :anti_abuse_settings)
  end
end
