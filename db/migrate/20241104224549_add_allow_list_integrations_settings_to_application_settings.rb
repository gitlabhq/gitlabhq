# frozen_string_literal: true

class AddAllowListIntegrationsSettingsToApplicationSettings < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  def change
    add_column :application_settings, :integrations, :jsonb, default: {}, null: false
  end
end
