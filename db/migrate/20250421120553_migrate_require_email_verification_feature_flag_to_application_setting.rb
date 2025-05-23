# frozen_string_literal: true

class MigrateRequireEmailVerificationFeatureFlagToApplicationSetting < Gitlab::Database::Migration[2.2]
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '18.1'

  def up
    return unless feature_flag_enabled?(:require_email_verification)

    execute <<-SQL
      UPDATE application_settings
      SET anti_abuse_settings = COALESCE(anti_abuse_settings, '{}'::jsonb) ||
      '{"require_email_verification_on_account_locked": true}'::jsonb,
      updated_at = NOW()
    SQL
  end

  def down
    execute <<-SQL
      UPDATE application_settings
      SET anti_abuse_settings = COALESCE(anti_abuse_settings, '{}'::jsonb) - 'require_email_verification_on_account_locked',
      updated_at = NOW()
    SQL
  end
end
