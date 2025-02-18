# frozen_string_literal: true

class CreateSecurityPipelineExecutionSchedules < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  def change
    create_table :security_pipeline_execution_project_schedules do |t|
      t.timestamps_with_timezone null: false
      t.datetime_with_timezone :next_run_at, null: false
      t.bigint :security_policy_id, null: false
      t.bigint :project_id, null: false
    end

    add_index(
      :security_pipeline_execution_project_schedules,
      [:next_run_at, :id],
      name: 'idx_security_pipeline_execution_project_schedules_next_run_at'
    )

    add_index(
      :security_pipeline_execution_project_schedules,
      [:security_policy_id, :id],
      name: 'idx_pipeline_execution_schedules_security_policy_id_and_id'
    )

    add_index(
      :security_pipeline_execution_project_schedules,
      [:project_id, :security_policy_id],
      unique: true,
      name: 'uniq_idx_pipeline_execution_schedules_projects_and_policies'
    )
  end
end
