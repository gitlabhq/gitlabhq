# frozen_string_literal: true

class AddNextRunAppliedDelayToSecurityPipelineExecutionProjectSchedules < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  def change
    add_column :security_pipeline_execution_project_schedules, :next_run_applied_delay, :integer
  end
end
