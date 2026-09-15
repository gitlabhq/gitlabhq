# frozen_string_literal: true

class AddDuoAutoModeEnabledToProjectSettings < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  def change
    add_column :project_settings, :duo_auto_mode_enabled, :boolean, default: false, null: false
  end
end
