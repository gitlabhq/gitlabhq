# frozen_string_literal: true

class AddDatabaseSettingsHashConstraintToApplicationSettings < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.7'

  CONSTRAINT_NAME = 'check_application_settings_database_settings_is_hash'

  def up
    add_check_constraint(
      :application_settings,
      "(jsonb_typeof(database_settings) = 'object')",
      CONSTRAINT_NAME
    )
  end

  def down
    remove_check_constraint(:application_settings, CONSTRAINT_NAME)
  end
end
