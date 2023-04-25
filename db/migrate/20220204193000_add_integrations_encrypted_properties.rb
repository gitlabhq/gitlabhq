# frozen_string_literal: true

class AddIntegrationsEncryptedProperties < Gitlab::Database::Migration[1.0]
  def change
    add_column :integrations, :encrypted_properties, :binary
    add_column :integrations, :encrypted_properties_iv, :binary
  end
end
