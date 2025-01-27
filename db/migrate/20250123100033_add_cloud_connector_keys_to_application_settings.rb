# frozen_string_literal: true

class AddCloudConnectorKeysToApplicationSettings < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  def change
    add_column :application_settings, :cloud_connector_keys, :jsonb
  end
end
