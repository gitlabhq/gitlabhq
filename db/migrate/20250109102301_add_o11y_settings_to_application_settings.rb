# frozen_string_literal: true

class AddO11ySettingsToApplicationSettings < Gitlab::Database::Migration[2.2]
  enable_lock_retries!
  milestone '17.8'

  def change
    add_column :application_settings, :observability_settings, :jsonb, default: {}, null: false
  end
end
