# frozen_string_literal: true

class AddIndexDuoWorkflowsOnUserIdUpdatedAt < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  disable_ddl_transaction!

  INDEX_NAME = 'index_duo_workflows_on_user_id_and_updated_at'

  def up
    add_concurrent_index(
      :duo_workflows_workflows,
      [:user_id, :updated_at],
      order: { updated_at: :desc },
      where: "workflow_definition != 'chat'",
      name: INDEX_NAME
    )
  end

  def down
    remove_concurrent_index_by_name :duo_workflows_workflows, INDEX_NAME
  end
end
