# frozen_string_literal: true

class AddPrefixedToCatalogResourceVersions < Gitlab::Database::Migration[2.2]
  milestone '17.00'

  def change
    add_column :catalog_resource_versions, :semver_prefixed, :boolean, default: false
  end
end
