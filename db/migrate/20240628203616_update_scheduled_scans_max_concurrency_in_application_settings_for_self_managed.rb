# frozen_string_literal: true

class UpdateScheduledScansMaxConcurrencyInApplicationSettingsForSelfManaged < Gitlab::Database::Migration[2.2]
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  enable_lock_retries!

  milestone '17.2'

  def up
    return if Gitlab.com?

    execute <<-SQL
      UPDATE application_settings
      SET security_policy_scheduled_scans_max_concurrency = 10000
      WHERE security_policy_scheduled_scans_max_concurrency = 100
    SQL
  end

  def down
    return if Gitlab.com?

    execute 'UPDATE application_settings SET security_policy_scheduled_scans_max_concurrency = 100'
  end
end
