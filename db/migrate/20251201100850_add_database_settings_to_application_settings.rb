# frozen_string_literal: true

class AddDatabaseSettingsToApplicationSettings < Gitlab::Database::Migration[2.3]
  milestone '18.7'

  def change
    add_column(
      :application_settings,
      :database_settings,
      :jsonb,
      default: {},
      null: false
    )
  end
end
