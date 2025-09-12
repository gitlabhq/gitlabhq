# frozen_string_literal: true

class RemoveIndexAiCatalogItemVersionDependenciesItemVersionId < Gitlab::Database::Migration[2.3]
  INDEX_NAME = 'index_ai_catalog_item_version_dependencies_on_item_version_id'

  disable_ddl_transaction!
  milestone '18.4'

  def up
    remove_concurrent_index_by_name :ai_catalog_item_version_dependencies, name: INDEX_NAME
  end

  def down
    add_concurrent_index :ai_catalog_item_version_dependencies, :ai_catalog_item_version_id, name: INDEX_NAME
  end
end
