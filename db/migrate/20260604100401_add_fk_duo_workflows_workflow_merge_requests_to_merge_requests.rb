# frozen_string_literal: true

class AddFkDuoWorkflowsWorkflowMergeRequestsToMergeRequests < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.2'

  TABLE = :duo_workflows_workflow_merge_requests

  def up
    add_concurrent_foreign_key TABLE, :merge_requests, column: :merge_request_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists TABLE, column: :merge_request_id
    end
  end
end
