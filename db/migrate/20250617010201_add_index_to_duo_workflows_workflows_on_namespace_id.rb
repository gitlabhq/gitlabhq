# frozen_string_literal: true

class AddIndexToDuoWorkflowsWorkflowsOnNamespaceId < Gitlab::Database::Migration[2.3]
  milestone '18.2'

  disable_ddl_transaction!

  TABLE_NAME = :duo_workflows_workflows
  INDEX_NAME = "index_duo_workflows_workflows_on_namespace_id"

  def up
    add_concurrent_index TABLE_NAME, :namespace_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end
end
