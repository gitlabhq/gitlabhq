# frozen_string_literal: true

class AddProjectDefaultsHashConstraintToApplicationSettings < Gitlab::Database::Migration[2.4]
  disable_ddl_transaction!
  milestone '19.6'

  CONSTRAINT_NAME = 'check_application_settings_project_defaults_is_hash'

  def up
    add_check_constraint :application_settings, "(jsonb_typeof(project_defaults) = 'object')", CONSTRAINT_NAME
  end

  def down
    remove_check_constraint :application_settings, CONSTRAINT_NAME
  end
end
