# frozen_string_literal: true

class AddEnabledZoektToUserPreferences < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    add_column :user_preferences, :enabled_zoekt, :boolean, null: false, default: true
  end
end
