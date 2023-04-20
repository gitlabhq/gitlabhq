# frozen_string_literal: true

class AddDatabaseApdexSettingsToApplicationSettings < Gitlab::Database::Migration[2.1]
  def change
    add_column :application_settings, :database_apdex_settings, :jsonb
  end
end
