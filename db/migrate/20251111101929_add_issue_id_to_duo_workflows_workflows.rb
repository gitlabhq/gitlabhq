# frozen_string_literal: true

class AddIssueIdToDuoWorkflowsWorkflows < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.6'

  INDEX_NAME = 'index_duo_workflows_workflows_on_issue_id'
  TABLE = :duo_workflows_workflows

  def up
    with_lock_retries do
      add_column TABLE, :issue_id, :bigint, null: true, if_not_exists: true
    end

    add_concurrent_index TABLE, :issue_id, name: INDEX_NAME
    add_concurrent_foreign_key TABLE, :issues, column: :issue_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_column TABLE, :issue_id, :bigint, null: true, if_exists: true
    end
  end
end
