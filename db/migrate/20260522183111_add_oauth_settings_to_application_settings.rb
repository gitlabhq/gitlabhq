# frozen_string_literal: true

class AddOauthSettingsToApplicationSettings < Gitlab::Database::Migration[2.3]
  milestone '19.1'
  disable_ddl_transaction!

  CONSTRAINT_NAME = 'check_application_settings_oauth_settings_is_hash'

  def up
    with_lock_retries do
      add_column :application_settings, :oauth_settings, :jsonb, default: {}, null: false, if_not_exists: true
    end

    add_check_constraint :application_settings, "(jsonb_typeof(oauth_settings) = 'object')", CONSTRAINT_NAME
  end

  def down
    remove_check_constraint :application_settings, CONSTRAINT_NAME

    with_lock_retries do
      remove_column :application_settings, :oauth_settings, if_exists: true
    end
  end
end
