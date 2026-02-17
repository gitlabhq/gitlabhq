# frozen_string_literal: true

class CreateScheduledPipelineExecutionPolicyTestRuns < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  def change
    create_table :security_scheduled_pipeline_execution_policy_test_runs do |t|
      t.bigint :security_policy_id, null: false
      t.bigint :project_id, null: false
      t.bigint :pipeline_id
      t.text :error_message, limit: 255
      t.integer :state, default: 0, null: false, limit: 2
      t.timestamps_with_timezone null: false

      t.index :security_policy_id, name: 'idx_spep_test_runs_policy_id'
      t.index :project_id, name: 'idx_spep_test_runs_project_id'
      t.index :pipeline_id, name: 'idx_spep_test_runs_pipeline_id'
    end
  end
end
