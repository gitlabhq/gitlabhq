# frozen_string_literal: true

class AddMcpServerSettingsHashConstraintToApplicationSettings < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.0'

  CONSTRAINT_NAME = 'check_application_settings_mcp_server_settings_is_hash'

  def up
    add_check_constraint(
      :application_settings,
      "(jsonb_typeof(mcp_server_settings) = 'object')",
      CONSTRAINT_NAME
    )
  end

  def down
    remove_check_constraint :application_settings, CONSTRAINT_NAME
  end
end
