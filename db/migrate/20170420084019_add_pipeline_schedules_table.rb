class AddPipelineSchedulesTable < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  def change
    create_table "ci_pipeline_schedules", force: :cascade do |t|
      t.integer "project_id"
      t.integer "trigger_id", null: false
      t.datetime "deleted_at"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string "cron"
      t.string "cron_timezone"
      t.datetime "next_run_at"
      t.string "ref"
      t.string "description"
      t.boolean "active"
    end

    add_index "ci_pipeline_schedules", ["active", "next_run_at"], name: "index_ci_pipeline_schedules_on_active_and_next_run_at", using: :btree
    add_index "ci_pipeline_schedules", ["next_run_at"], name: "index_ci_pipeline_schedules_on_next_run_at", using: :btree
    add_index "ci_pipeline_schedules", ["project_id"], name: "index_ci_pipeline_schedules_on_project_id", using: :btree
  end
end
