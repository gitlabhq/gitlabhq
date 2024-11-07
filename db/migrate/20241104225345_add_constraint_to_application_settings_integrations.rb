# frozen_string_literal: true

class AddConstraintToApplicationSettingsIntegrations < Gitlab::Database::Migration[2.2]
  milestone '17.6'
  disable_ddl_transaction!

  CONSTRAINT_NAME = 'check_application_settings_integrations_is_hash'

  def up
    add_check_constraint(
      :application_settings,
      "(jsonb_typeof(integrations) = 'object')",
      CONSTRAINT_NAME
    )
  end

  def down
    remove_check_constraint :application_settings, CONSTRAINT_NAME
  end
end
