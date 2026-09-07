# frozen_string_literal: true

class AddIdempotencyKeyToDuoWorkflowsWorkflowMergeRequests < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  disable_ddl_transaction!

  CONSTRAINT_NAME = 'check_duo_wf_wf_mrs_idempotency_key_limit'
  INDEX_NAME = 'index_duo_wf_wf_mrs_on_project_id_and_idempotency_key'

  def up
    add_column :duo_workflows_workflow_merge_requests, :idempotency_key, :text, if_not_exists: true

    add_text_limit :duo_workflows_workflow_merge_requests, :idempotency_key, 255,
      constraint_name: CONSTRAINT_NAME, validate: false

    add_concurrent_index :duo_workflows_workflow_merge_requests, [:project_id, :idempotency_key],
      where: 'idempotency_key IS NOT NULL',
      name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :duo_workflows_workflow_merge_requests, INDEX_NAME

    remove_text_limit :duo_workflows_workflow_merge_requests, :idempotency_key, constraint_name: CONSTRAINT_NAME

    remove_column :duo_workflows_workflow_merge_requests, :idempotency_key, if_exists: true
  end
end
