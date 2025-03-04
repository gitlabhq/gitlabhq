# frozen_string_literal: true

class AddCiPipelineScheduleVariablesProjectIdNotNull < Gitlab::Database::Migration[2.2]
  milestone '17.10'
  disable_ddl_transaction!

  def up
    add_not_null_constraint :ci_pipeline_schedule_variables, :project_id
  end

  def down
    remove_not_null_constraint :ci_pipeline_schedule_variables, :project_id
  end
end
