# frozen_string_literal: true

class AddRawToCiPipelineScheduleVariables < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def change
    add_column :ci_pipeline_schedule_variables, :raw, :boolean, null: false, default: true
  end
end
