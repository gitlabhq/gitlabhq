# frozen_string_literal: true

class AddIndexToUserPreferences < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :user_preferences, :gitpod_enabled, name: :index_user_preferences_on_gitpod_enabled
  end

  def down
    remove_concurrent_index :user_preferences, :gitpod_enabled, name: :index_user_preferences_on_gitpod_enabled
  end
end
