# frozen_string_literal: true

class AddNewUiEnabledToUserPreferences < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  def change
    add_column :user_preferences, :new_ui_enabled, :boolean
  end
end
