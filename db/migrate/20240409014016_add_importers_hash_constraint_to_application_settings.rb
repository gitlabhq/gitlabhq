# frozen_string_literal: true

class AddImportersHashConstraintToApplicationSettings < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.0'

  CONSTRAINT_NAME = 'check_application_settings_importers_is_hash'

  def up
    add_check_constraint(
      :application_settings,
      "(jsonb_typeof(importers) = 'object')",
      CONSTRAINT_NAME
    )
  end

  def down
    remove_check_constraint :application_settings, CONSTRAINT_NAME
  end
end
