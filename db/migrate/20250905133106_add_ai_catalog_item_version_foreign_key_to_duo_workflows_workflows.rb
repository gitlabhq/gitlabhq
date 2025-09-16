# frozen_string_literal: true

class AddAiCatalogItemVersionForeignKeyToDuoWorkflowsWorkflows < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.4'
  TABLE_NAME = :duo_workflows_workflows
  COLUMN_NAME = :ai_catalog_item_version_id
  INDEX_NAME = "index_#{TABLE_NAME}_on_#{COLUMN_NAME}"

  def up
    add_column TABLE_NAME, COLUMN_NAME, :bigint, if_not_exists: true

    add_concurrent_index TABLE_NAME, COLUMN_NAME, name: INDEX_NAME

    add_concurrent_foreign_key(
      TABLE_NAME,
      :ai_catalog_item_versions,
      column: COLUMN_NAME,
      on_delete: :nullify
    )
  end

  def down
    remove_column TABLE_NAME, COLUMN_NAME, if_exists: true
  end
end
