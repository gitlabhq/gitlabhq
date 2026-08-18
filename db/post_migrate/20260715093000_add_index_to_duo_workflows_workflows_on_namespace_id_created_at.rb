# frozen_string_literal: true

class AddIndexToDuoWorkflowsWorkflowsOnNamespaceIdCreatedAt < Gitlab::Database::Migration[2.3]
  milestone '19.3'
  disable_ddl_transaction!

  INDEX_NAME = 'index_duo_workflows_workflows_on_namespace_id_created_at'

  def up
    add_concurrent_index(
      :duo_workflows_workflows,
      [:namespace_id, :created_at],
      order: { created_at: :DESC },
      where: "workflow_definition != 'chat'",
      name: INDEX_NAME
    )
  end

  def down
    remove_concurrent_index_by_name(
      :duo_workflows_workflows,
      INDEX_NAME
    )
  end
end
