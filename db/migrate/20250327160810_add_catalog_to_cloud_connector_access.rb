# frozen_string_literal: true

class AddCatalogToCloudConnectorAccess < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  def change
    add_column :cloud_connector_access, :catalog, :jsonb
  end
end
