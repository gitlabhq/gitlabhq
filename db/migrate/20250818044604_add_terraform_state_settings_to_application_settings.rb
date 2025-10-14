# frozen_string_literal: true

class AddTerraformStateSettingsToApplicationSettings < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  disable_ddl_transaction!

  CONSTRAINT_NAME = 'check_terraform_state_settings_is_hash'

  def up
    add_column :application_settings, :terraform_state_settings, :jsonb, default: {}, null: false, if_not_exists: true

    add_check_constraint(
      :application_settings,
      "(jsonb_typeof(terraform_state_settings) = 'object')",
      CONSTRAINT_NAME
    )
  end

  def down
    remove_column :application_settings, :terraform_state_settings, if_exists: true
  end
end
