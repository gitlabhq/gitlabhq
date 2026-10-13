# frozen_string_literal: true

class AddIndexAiCatalogItemConsumersOnProjectIdAndItemId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.6'

  TABLE_NAME = :ai_catalog_item_consumers
  INDEX_NAME = 'index_ai_catalog_item_consumers_on_project_id_and_item_id'

  def up
    add_concurrent_index TABLE_NAME, %i[project_id ai_catalog_item_id], include: :enabled, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end
end
