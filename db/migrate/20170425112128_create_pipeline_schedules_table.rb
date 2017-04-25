class CreatePipelineSchedulesTable < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  DOWNTIME = false

  def up
    create_table :ci_pipeline_schedules do |t|
      t.string :description
      t.string :ref
      t.string :cron
      t.string :cron_timezone
      t.datetime :next_run_at
      t.integer :project_id
      t.integer :owner_id
      t.boolean :active, default: true
      t.datetime :deleted_at

      t.timestamps
    end

    add_concurrent_index :ci_pipeline_schedules, :project_id
    add_concurrent_index :ci_pipeline_schedules, [:next_run_at, :active]

    add_concurrent_foreign_key :ci_pipeline_schedules, :projects, column: :project_id
  end

  def down
    drop_table :ci_pipeline_schedules
  end
end
