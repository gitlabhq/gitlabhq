# frozen_string_literal: true

class AddKeyboardShortcutsToggleToUserPreferences < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    add_column :user_preferences, :keyboard_shortcuts_enabled, :boolean, default: true, null: false
  end
end
