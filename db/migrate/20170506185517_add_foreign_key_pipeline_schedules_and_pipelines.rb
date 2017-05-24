class AddForeignKeyPipelineSchedulesAndPipelines < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    on_delete =
      if Gitlab::Database.mysql?
        :nullify
      else
        'SET NULL'
      end

    add_concurrent_foreign_key  :ci_pipelines, :ci_pipeline_schedules,
      column: :pipeline_schedule_id, on_delete: on_delete
  end

  def down
    remove_foreign_key :ci_pipelines, column: :pipeline_schedule_id
  end
end
