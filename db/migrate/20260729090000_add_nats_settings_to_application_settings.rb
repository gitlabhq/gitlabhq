# frozen_string_literal: true

class AddNatsSettingsToApplicationSettings < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  def up
    add_column :application_settings, :nats_settings, :jsonb, null: false, default: {}
  end

  def down
    remove_column :application_settings, :nats_settings, if_exists: true
  end
end
