# frozen_string_literal: true

class AddInstanceJobTokenScopeEnabledToAppSettings < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  def change
    add_column :application_settings,
      :enforce_ci_inbound_job_token_scope_enabled,
      :boolean, null: false, default: false
  end
end
