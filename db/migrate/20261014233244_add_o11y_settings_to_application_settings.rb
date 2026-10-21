# frozen_string_literal: true

class AddO11ySettingsToApplicationSettings < Gitlab::Database::Migration[2.4]
  milestone '19.6'
  disable_ddl_transaction!

  # The legacy `observability_settings` column already uses
  # `check_application_settings_o11y_settings_is_hash`.
  CONSTRAINT_NAME = 'check_application_settings_current_o11y_settings_is_hash'

  def up
    with_lock_retries do
      add_column :application_settings, :o11y_settings, :jsonb, default: {}, null: false, if_not_exists: true
      add_column :application_settings, :o11y_provisioner_api_key, :jsonb, null: true, if_not_exists: true
    end

    add_check_constraint :application_settings, "(jsonb_typeof(o11y_settings) = 'object')", CONSTRAINT_NAME
  end

  def down
    remove_check_constraint :application_settings, CONSTRAINT_NAME

    with_lock_retries do
      remove_column :application_settings, :o11y_provisioner_api_key, if_exists: true
      remove_column :application_settings, :o11y_settings, if_exists: true
    end
  end
end
