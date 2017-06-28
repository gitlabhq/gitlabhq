class AddForeignKeyToPipelineSchedules < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :ci_pipeline_schedules, :projects, column: :project_id
  end

  def down
    remove_foreign_key :ci_pipeline_schedules, :projects
  end
end
