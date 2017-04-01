class CreateCiTriggerSchedules < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    create_table :ci_trigger_schedules do |t|
      t.integer "project_id"
      t.integer "trigger_id", null: false
      t.datetime "deleted_at"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string "cron"
      t.string "cron_time_zone"
      t.datetime "next_run_at"
    end

    add_index :ci_trigger_schedules, ["next_run_at"], name: "index_ci_trigger_schedules_on_next_run_at", using: :btree
    add_index :ci_trigger_schedules, ["project_id"], name: "index_ci_trigger_schedules_on_project_id", using: :btree
    add_concurrent_foreign_key :ci_trigger_schedules, :ci_triggers, column: :trigger_id, on_delete: :cascade
  end

  def down
    remove_foreign_key :ci_trigger_schedules, column: :trigger_id
    drop_table :ci_trigger_schedules
  end
end
