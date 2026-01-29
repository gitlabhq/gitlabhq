# frozen_string_literal: true

class AddProjectForeignKeyToScheduledPipelineExecutionPolicyTestRuns < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.9'

  def up
    add_concurrent_foreign_key :security_scheduled_pipeline_execution_policy_test_runs, :projects, column: :project_id,
      on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :security_scheduled_pipeline_execution_policy_test_runs, column: :project_id
    end
  end
end
