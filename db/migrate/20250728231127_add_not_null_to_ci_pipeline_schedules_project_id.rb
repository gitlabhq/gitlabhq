# frozen_string_literal: true

class AddNotNullToCiPipelineSchedulesProjectId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.3'

  def up
    add_not_null_constraint(:ci_pipeline_schedules, :project_id)
  end

  def down
    remove_not_null_constraint(:ci_pipeline_schedules, :project_id)
  end
end
