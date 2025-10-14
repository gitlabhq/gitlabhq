# frozen_string_literal: true

class AddNamespaceDeletionSettingsHashConstraintToApplicationSettings < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.5'

  CONSTRAINT_NAME = 'check_application_settings_namespace_deletion_settings_is_hash'

  def up
    add_check_constraint(
      :application_settings,
      "(jsonb_typeof(namespace_deletion_settings) = 'object')",
      CONSTRAINT_NAME
    )
  end

  def down
    remove_check_constraint :application_settings, CONSTRAINT_NAME
  end
end
