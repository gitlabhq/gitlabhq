# frozen_string_literal: true

class AddProjectShortcutButtonsToUserPreferences < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    add_column :user_preferences, :project_shortcut_buttons, :boolean, default: true, null: false
  end
end
