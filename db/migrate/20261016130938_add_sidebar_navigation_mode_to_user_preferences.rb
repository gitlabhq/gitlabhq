# frozen_string_literal: true

class AddSidebarNavigationModeToUserPreferences < Gitlab::Database::Migration[2.3]
  milestone '19.6'

  def change
    add_column :user_preferences, :sidebar_navigation_mode, :smallint
  end
end
