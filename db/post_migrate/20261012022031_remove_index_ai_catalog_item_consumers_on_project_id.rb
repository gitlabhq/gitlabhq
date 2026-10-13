# frozen_string_literal: true

class RemoveIndexAiCatalogItemConsumersOnProjectId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.6'

  TABLE_NAME = :ai_catalog_item_consumers
  INDEX_NAME = 'index_ai_catalog_item_consumers_on_project_id'

  def up
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end

  def down
    add_concurrent_index TABLE_NAME, :project_id, name: INDEX_NAME
  end
end
