class AddPipelineScheduleIdToPipelines < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :ci_pipelines, :pipeline_schedule_id, :integer
  end
end
