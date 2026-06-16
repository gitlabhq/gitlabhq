# frozen_string_literal: true

class AddDependencyManagementSettingsHashConstraintToApplicationSettings < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.1'

  CONSTRAINT_NAME = 'check_app_settings_dependency_management_settings_is_hash'

  def up
    add_check_constraint(
      :application_settings,
      "(jsonb_typeof(dependency_management_settings) = 'object')",
      CONSTRAINT_NAME
    )
  end

  def down
    remove_check_constraint :application_settings, CONSTRAINT_NAME
  end
end
