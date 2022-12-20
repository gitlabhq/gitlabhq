# frozen_string_literal: true

class AddMaxTerraformStateSizeBytesToApplicationSettings < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  CONSTRAINT_NAME = "app_settings_max_terraform_state_size_bytes_check"

  def up
    add_column(
      :application_settings,
      :max_terraform_state_size_bytes,
      :integer,
      null: false,
      default: 0,
      if_not_exists: true
    )

    add_check_constraint :application_settings, "max_terraform_state_size_bytes >= 0", CONSTRAINT_NAME
  end

  def down
    remove_column :application_settings, :max_terraform_state_size_bytes, if_exists: true
  end
end
