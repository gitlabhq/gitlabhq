# frozen_string_literal: true

class AddGroupSettingsToApplicationSettings < Gitlab::Database::Migration[2.2]
  milestone '18.0'
  disable_ddl_transaction!

  CONSTRAINT_NAME = 'check_application_settings_group_settings_is_hash'

  def up
    with_lock_retries do
      add_column :application_settings, :group_settings, :jsonb, default: {}, null: false
    end

    add_check_constraint :application_settings, "(jsonb_typeof(group_settings) = 'object')", CONSTRAINT_NAME
  end

  def down
    remove_check_constraint :application_settings, CONSTRAINT_NAME

    with_lock_retries do
      remove_column :application_settings, :group_settings
    end
  end
end
