# frozen_string_literal: true

class AddCiPipelineScheduleVariablesProjectIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  def up
    install_sharding_key_assignment_trigger(
      table: :ci_pipeline_schedule_variables,
      sharding_key: :project_id,
      parent_table: :ci_pipeline_schedules,
      parent_sharding_key: :project_id,
      foreign_key: :pipeline_schedule_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :ci_pipeline_schedule_variables,
      sharding_key: :project_id,
      parent_table: :ci_pipeline_schedules,
      parent_sharding_key: :project_id,
      foreign_key: :pipeline_schedule_id
    )
  end
end
