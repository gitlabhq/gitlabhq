# frozen_string_literal: true

class MigrateDelayDeleteOwnUserFeatureFlagToApplicationSetting < Gitlab::Database::Migration[2.3]
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '18.2'

  def up
    up_migrate_to_jsonb_setting(
      feature_flag_name: :delay_delete_own_user,
      setting_name: :delay_user_account_self_deletion,
      jsonb_column_name: :anti_abuse_settings,
      default_enabled: false
    )
  end

  def down
    down_migrate_to_jsonb_setting(
      setting_name: :delay_user_account_self_deletion,
      jsonb_column_name: :anti_abuse_settings
    )
  end
end
