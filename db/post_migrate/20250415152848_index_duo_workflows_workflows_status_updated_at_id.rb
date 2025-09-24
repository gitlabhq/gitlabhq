# frozen_string_literal: true

class IndexDuoWorkflowsWorkflowsStatusUpdatedAtId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '18.0'

  INDEX_NAME = 'idx_workflows_status_updated_at_id'

  def up
    add_concurrent_index :duo_workflows_workflows, [:status, :updated_at, :id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :duo_workflows_workflows, INDEX_NAME
  end
end
