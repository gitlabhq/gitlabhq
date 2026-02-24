# frozen_string_literal: true

class DropNamespaceDeletionSettingsColumn < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.10'

  CONSTRAINT_NAME = 'check_application_settings_namespace_deletion_settings_is_hash'

  def up
    remove_column :application_settings, :namespace_deletion_settings
  end

  def down
    add_column(
      :application_settings,
      :namespace_deletion_settings,
      :jsonb,
      default: {},
      null: false,
      if_not_exists: true
    )

    add_check_constraint(
      :application_settings,
      "(jsonb_typeof(namespace_deletion_settings) = 'object')",
      CONSTRAINT_NAME
    )
  end
end
