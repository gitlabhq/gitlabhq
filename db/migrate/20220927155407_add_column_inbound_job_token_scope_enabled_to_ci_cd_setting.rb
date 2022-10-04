# frozen_string_literal: true

class AddColumnInboundJobTokenScopeEnabledToCiCdSetting < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def up
    add_column :project_ci_cd_settings, :inbound_job_token_scope_enabled, :boolean, default: false, null: false
  end

  def down
    remove_column :project_ci_cd_settings, :inbound_job_token_scope_enabled
  end
end
