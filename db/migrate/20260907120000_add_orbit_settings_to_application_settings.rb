# frozen_string_literal: true

class AddOrbitSettingsToApplicationSettings < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  def up
    add_column :application_settings, :orbit_settings, :jsonb, default: {}, null: false
  end

  def down
    remove_column :application_settings, :orbit_settings
  end
end
