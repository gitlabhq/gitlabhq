# frozen_string_literal: true

class AddAgentIdentitiesColumnsToDuoWorkflowsWorkflows < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  disable_ddl_transaction!

  TABLE = :duo_workflows_workflows

  def up
    with_lock_retries do
      add_column TABLE, :agent_type, :text, if_not_exists: true
      add_column TABLE, :jsonl_sha256, :text, if_not_exists: true
      add_column TABLE, :idempotency_key, :text, if_not_exists: true
      add_column TABLE, :sync_type, :smallint, if_not_exists: true
      add_column TABLE, :agent_identity_id, :bigint, if_not_exists: true
    end

    add_text_limit TABLE, :agent_type, 50, validate: false
    add_text_limit TABLE, :jsonl_sha256, 64, validate: false
    add_text_limit TABLE, :idempotency_key, 255, validate: false

    add_concurrent_index TABLE,
      [:project_id, :user_id, :idempotency_key],
      unique: true,
      where: 'idempotency_key IS NOT NULL AND project_id IS NOT NULL',
      name: 'index_duo_workflows_workflows_on_project_user_idempotency_key'

    add_concurrent_index TABLE,
      :agent_identity_id,
      where: 'agent_identity_id IS NOT NULL',
      name: 'index_duo_workflows_workflows_on_agent_identity_id'
  end

  def down
    remove_concurrent_index_by_name TABLE, 'index_duo_workflows_workflows_on_project_user_idempotency_key'
    remove_concurrent_index_by_name TABLE, 'index_duo_workflows_workflows_on_agent_identity_id'

    with_lock_retries do
      remove_column TABLE, :agent_type, if_exists: true
      remove_column TABLE, :jsonl_sha256, if_exists: true
      remove_column TABLE, :idempotency_key, if_exists: true
      remove_column TABLE, :sync_type, if_exists: true
      remove_column TABLE, :agent_identity_id, if_exists: true
    end
  end
end
