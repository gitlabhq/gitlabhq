# frozen_string_literal: true

class AddProjectIdToCiPipelineScheduleVariables < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  def change
    add_column :ci_pipeline_schedule_variables, :project_id, :bigint
  end
end
