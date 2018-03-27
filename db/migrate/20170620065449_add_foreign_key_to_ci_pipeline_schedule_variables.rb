class AddForeignKeyToCiPipelineScheduleVariables < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key(:ci_pipeline_schedule_variables, :ci_pipeline_schedules, column: :pipeline_schedule_id)
  end

  def down
    remove_foreign_key(:ci_pipeline_schedule_variables, column: :pipeline_schedule_id)
  end
end
