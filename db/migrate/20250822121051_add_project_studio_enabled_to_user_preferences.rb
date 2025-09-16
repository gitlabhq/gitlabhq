# frozen_string_literal: true

class AddProjectStudioEnabledToUserPreferences < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  def change
    add_column :user_preferences, :project_studio_enabled, :boolean, default: false, null: false, if_not_exists: true
  end
end
