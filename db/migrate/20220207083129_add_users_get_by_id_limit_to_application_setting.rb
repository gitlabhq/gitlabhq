# frozen_string_literal: true

class AddUsersGetByIdLimitToApplicationSetting < Gitlab::Database::Migration[1.0]
  enable_lock_retries!

  def up
    add_column :application_settings, :users_get_by_id_limit, :integer, null: false, default: 300
    add_column :application_settings, :users_get_by_id_limit_allowlist, :text, array: true, limit: 255, null: false, default: []
  end

  def down
    remove_column :application_settings, :users_get_by_id_limit
    remove_column :application_settings, :users_get_by_id_limit_allowlist
  end
end
