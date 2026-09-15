# frozen_string_literal: true

class AddFileStoreToCatalogBundledResourceVersions < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  def change
    add_column :catalog_bundled_resource_versions, :file_store, :integer, limit: 2, null: false, default: 1
  end
end
