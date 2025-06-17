# frozen_string_literal: true

class AddDisplaySettingsToUserPreferences < Gitlab::Database::Migration[2.3]
  milestone '18.1'
  disable_ddl_transaction!

  CONSTRAINT_NAME = 'check_display_settings_is_hash'

  def up
    with_lock_retries do
      add_column :work_item_type_user_preferences, :display_settings, :jsonb, default: {}, null: false
    end

    add_check_constraint :work_item_type_user_preferences, "(jsonb_typeof(display_settings) = 'object')",
      CONSTRAINT_NAME
  end

  def down
    remove_check_constraint :work_item_type_user_preferences, CONSTRAINT_NAME

    with_lock_retries do
      remove_column :work_item_type_user_preferences, :display_settings
    end
  end
end
