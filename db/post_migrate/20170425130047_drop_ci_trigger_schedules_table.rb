class DropCiTriggerSchedulesTable < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    drop_table :ci_trigger_schedules
  end

  def down
    create_table "ci_trigger_schedules", force: :cascade do |t|
      t.integer "project_id"
      t.integer "trigger_id", null: false
      t.datetime "deleted_at"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string "cron"
      t.string "cron_timezone"
      t.datetime "next_run_at"
      t.string "ref"
      t.boolean "active"
    end

    add_index "ci_trigger_schedules", %w(active next_run_at), name: "index_ci_trigger_schedules_on_active_and_next_run_at", using: :btree
    add_index "ci_trigger_schedules", ["project_id"], name: "index_ci_trigger_schedules_on_project_id", using: :btree
    add_index "ci_trigger_schedules", ["next_run_at"], name: "index_ci_trigger_schedules_on_next_run_at"

    add_concurrent_foreign_key "ci_trigger_schedules", "ci_triggers", column: :trigger_id, on_delete: :cascade
  end
end
