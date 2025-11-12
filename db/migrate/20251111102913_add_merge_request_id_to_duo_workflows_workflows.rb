# frozen_string_literal: true

class AddMergeRequestIdToDuoWorkflowsWorkflows < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.6'

  INDEX_NAME = 'index_duo_workflows_workflows_on_merge_request_id'
  TABLE = :duo_workflows_workflows

  def up
    with_lock_retries do
      add_column TABLE, :merge_request_id, :bigint, null: true, if_not_exists: true
    end

    add_concurrent_index TABLE, :merge_request_id, name: INDEX_NAME
    add_concurrent_foreign_key TABLE, :merge_requests, column: :merge_request_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_column TABLE, :merge_request_id, :bigint, null: true, if_exists: true
    end
  end
end
