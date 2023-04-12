# frozen_string_literal: true

class AddSilentModeEnabledToApplicationSettings < Gitlab::Database::Migration[2.1]
  def change
    add_column :application_settings, :silent_mode_enabled, :boolean, default: false, null: false, if_not_exists: true
  end
end
