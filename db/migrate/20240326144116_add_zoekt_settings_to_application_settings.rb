# frozen_string_literal: true

class AddZoektSettingsToApplicationSettings < Gitlab::Database::Migration[2.2]
  enable_lock_retries!
  milestone '16.11'

  def change
    add_column :application_settings, :zoekt_settings, :jsonb, default: {}, null: false
  end
end
