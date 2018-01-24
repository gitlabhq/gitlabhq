# rubocop:disable Migration/Datetime
# rubocop:disable Migration/Timestamps
class CreatePipelineSchedulesTable < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

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

      t.timestamps null: true
    end

    add_index(:ci_pipeline_schedules, :project_id)
    add_index(:ci_pipeline_schedules, [:next_run_at, :active])
  end

  def down
    drop_table :ci_pipeline_schedules
  end
end
