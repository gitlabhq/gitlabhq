# frozen_string_literal: true

class ChangeCiJobTokenAllowlistSettingDefault < Gitlab::Database::Migration[2.3]
  milestone '18.0'

  def change
    change_column_default :application_settings, :enforce_ci_inbound_job_token_scope_enabled, from: false, to: true
  end
end
