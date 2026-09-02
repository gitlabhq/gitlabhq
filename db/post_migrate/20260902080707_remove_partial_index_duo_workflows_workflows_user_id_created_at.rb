# frozen_string_literal: true

class RemovePartialIndexDuoWorkflowsWorkflowsUserIdCreatedAt < Gitlab::Database::Migration[2.3]
  milestone '19.4'
  disable_ddl_transaction!

  INDEX_NAME = 'index_duo_workflows_workflows_on_user_id_created_at'

  def up
    remove_concurrent_index_by_name(
      :duo_workflows_workflows,
      INDEX_NAME
    )
  end

  def down
    add_concurrent_index(
      :duo_workflows_workflows,
      [:user_id, :created_at],
      order: { created_at: :DESC },
      where: "workflow_definition != 'chat'",
      name: INDEX_NAME
    )
  end
end
