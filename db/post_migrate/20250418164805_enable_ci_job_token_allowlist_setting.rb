# frozen_string_literal: true

class EnableCiJobTokenAllowlistSetting < Gitlab::Database::Migration[2.3]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  milestone '18.0'

  def up
    execute <<~SQL
      UPDATE application_settings
      SET enforce_ci_inbound_job_token_scope_enabled = true
    SQL
  end

  def down
    execute <<~SQL
      UPDATE application_settings
      SET enforce_ci_inbound_job_token_scope_enabled = false
    SQL
  end
end
