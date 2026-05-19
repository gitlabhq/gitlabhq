# frozen_string_literal: true

class CreateSecurityPolicySchedulePipelines < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  def change
    create_table :security_policy_schedule_pipelines do |t|
      t.bigint :security_policy_id, null: false
      t.bigint :pipeline_id, null: false
      t.bigint :project_id, null: false

      t.timestamps_with_timezone null: false

      t.index :pipeline_id, unique: true, name: 'idx_security_policy_schedule_pipelines_on_pipeline_id'
      t.index :security_policy_id, name: 'idx_sec_pol_sched_pipes_on_policy_id'
      t.index :project_id, name: 'idx_sec_pol_sched_pipes_on_project_id'
    end
  end
end
