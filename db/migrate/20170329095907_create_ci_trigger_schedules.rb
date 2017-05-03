class CreateCiTriggerSchedules < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :ci_trigger_schedules do |t|
      t.integer "project_id"
      t.integer "trigger_id", null: false
      t.datetime "deleted_at"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string "cron"
      t.string "cron_timezone"
      t.datetime "next_run_at"
    end

    add_index :ci_trigger_schedules, :next_run_at
    add_index :ci_trigger_schedules, :project_id
  end
end
