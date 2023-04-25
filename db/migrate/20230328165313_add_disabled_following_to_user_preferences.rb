# frozen_string_literal: true

class AddDisabledFollowingToUserPreferences < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    add_column :user_preferences, :enabled_following, :boolean, default: true, null: false
  end
end
