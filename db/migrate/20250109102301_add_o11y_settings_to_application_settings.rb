# frozen_string_literal: true

class AddO11ySettingsToApplicationSettings < Gitlab::Database::Migration[2.2]
  milestone '17.8'

  def change
    add_column :application_settings, :observability_settings, :jsonb, default: {}, null: false
  end
end
