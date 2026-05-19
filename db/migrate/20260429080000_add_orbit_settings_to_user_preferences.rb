# frozen_string_literal: true

class AddOrbitSettingsToUserPreferences < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  def change
    add_column :user_preferences, :orbit_settings, :jsonb, default: {}, null: false, if_not_exists: true
  end
end
