# frozen_string_literal: true

class AddUseNewNavigationToUserPreferences < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def change
    add_column :user_preferences, :use_new_navigation, :boolean, default: nil, null: true
  end
end
