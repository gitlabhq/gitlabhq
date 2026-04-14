# frozen_string_literal: true

class RemoveProjectStudioEnabledFromUserPreferences < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  def up
    with_lock_retries do
      remove_column :user_preferences, :project_studio_enabled
    end
  end

  def down
    add_column :user_preferences, :project_studio_enabled, :boolean, default: false, null: false
  end
end
