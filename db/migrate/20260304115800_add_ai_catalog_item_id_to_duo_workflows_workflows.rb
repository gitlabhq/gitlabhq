# frozen_string_literal: true

class AddAiCatalogItemIdToDuoWorkflowsWorkflows < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.10'

  INDEX_NAME = "index_duo_workflows_workflows_on_ai_catalog_item_id"
  FK_NAME = "fk_duo_workflows_workflows_ai_catalog_item_id"

  def up
    with_lock_retries do
      add_column :duo_workflows_workflows, :ai_catalog_item_id, :bigint, null: true, if_not_exists: true
    end

    add_concurrent_index :duo_workflows_workflows, :ai_catalog_item_id, name: INDEX_NAME

    add_concurrent_foreign_key :duo_workflows_workflows, :ai_catalog_items,
      column: :ai_catalog_item_id,
      on_delete: :nullify,
      name: FK_NAME
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :duo_workflows_workflows, column: :ai_catalog_item_id, name: FK_NAME
      remove_column :duo_workflows_workflows, :ai_catalog_item_id, if_exists: true
    end
  end
end
