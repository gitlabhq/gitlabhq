# frozen_string_literal: true

class AddDuoSettingsToApplicationSettings < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  def up
    add_column :application_settings, :duo_settings, :jsonb, null: false, default: {}
  end

  def down
    remove_column :application_settings, :duo_settings, if_exists: true
  end
end
