# frozen_string_literal: true

class AddDefaultProfilePreferencesToApplicationSettings < Gitlab::Database::Migration[2.3]
  milestone '18.2'

  def change
    add_column :application_settings, :default_profile_preferences, :jsonb, default: {}, null: false
  end
end
