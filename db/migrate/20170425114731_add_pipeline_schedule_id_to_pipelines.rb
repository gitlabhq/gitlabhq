class AddPipelineScheduleIdToPipelines < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :ci_pipelines, :pipeline_schedule_id, :integer
  end
end
