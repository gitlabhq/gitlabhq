# frozen_string_literal: true

class RemoveIndexDuoWorkflowsWorkflowsOnUserId < Gitlab::Database::Migration[2.3]
  milestone '19.4'
  disable_ddl_transaction!

  INDEX_NAME = 'index_duo_workflows_workflows_on_user_id'

  # Redundant with index_duo_workflows_workflows_on_user_id_and_created_at,
  # whose leading column covers all user_id-only scans.
  def up
    remove_concurrent_index_by_name(
      :duo_workflows_workflows,
      INDEX_NAME
    )
  end

  def down
    add_concurrent_index(
      :duo_workflows_workflows,
      :user_id,
      name: INDEX_NAME
    )
  end
end
