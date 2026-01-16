# frozen_string_literal: true

class RemoveNewUiEnabledFromUserPreferences < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  def up
    remove_column :user_preferences, :new_ui_enabled
  end

  def down
    add_column :user_preferences, :new_ui_enabled, :boolean
  end
end
