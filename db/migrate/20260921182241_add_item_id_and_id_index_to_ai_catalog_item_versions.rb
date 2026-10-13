# frozen_string_literal: true

class AddItemIdAndIdIndexToAiCatalogItemVersions < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  disable_ddl_transaction!

  INDEX_NAME = 'index_ai_catalog_item_versions_on_ai_catalog_item_id_and_id'

  def up
    # Supports the composite foreign key from
    # ai_catalog_item_version_dependencies (dependency_id, dependency_version_id)
    add_concurrent_index :ai_catalog_item_versions, [:ai_catalog_item_id, :id], unique: true, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :ai_catalog_item_versions, INDEX_NAME
  end
end
