# frozen_string_literal: true

class AddGlobalSearchSettingsToApplicationSettings < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  def change
    add_column :application_settings, :search, :jsonb, default: {}, null: false
  end
end
