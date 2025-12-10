# frozen_string_literal: true

class AddCreatedByIdIndexToAiCatalogItemVersions < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.7'

  INDEX_NAME = 'index_ai_catalog_item_versions_on_created_by_id'

  def up
    add_concurrent_index :ai_catalog_item_versions, :created_by_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :ai_catalog_item_versions, name: INDEX_NAME
  end
end
