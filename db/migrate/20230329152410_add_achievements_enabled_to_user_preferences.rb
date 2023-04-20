# frozen_string_literal: true

class AddAchievementsEnabledToUserPreferences < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    add_column :user_preferences, :achievements_enabled, :boolean, default: true, null: false
  end
end
