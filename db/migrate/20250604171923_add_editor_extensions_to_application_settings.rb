# frozen_string_literal: true

class AddEditorExtensionsToApplicationSettings < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.1'

  CONSTRAINT_NAME = 'check_application_settings_editor_extensions_is_hash'

  def up
    with_lock_retries do
      add_column :application_settings, :editor_extensions, :jsonb, default: {}, null: false, if_not_exists: true
    end

    add_check_constraint(
      :application_settings,
      "(jsonb_typeof(editor_extensions) = 'object')",
      CONSTRAINT_NAME
    )
  end

  def down
    remove_check_constraint :application_settings, CONSTRAINT_NAME

    with_lock_retries do
      remove_column :application_settings, :editor_extensions, if_exists: true
    end
  end
end
