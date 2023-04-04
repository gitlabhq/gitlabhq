# frozen_string_literal: true

class AddPinnedNavItemsToUserPreference < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    add_column :user_preferences, :pinned_nav_items, :jsonb, null: false, default: {}
  end
end
