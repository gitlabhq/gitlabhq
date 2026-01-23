# frozen_string_literal: true

class AddTopologyServiceSettingsToApplicationSettings < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  def change
    add_column :application_settings, :topology_service_settings, :jsonb, default: {}, null: false
  end
end
