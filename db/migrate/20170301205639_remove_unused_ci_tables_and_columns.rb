# rubocop:disable Migration/RemoveColumn
# rubocop:disable Migration/Datetime
class RemoveUnusedCiTablesAndColumns < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = true
  DOWNTIME_REASON =
    'Remove unused columns in used tables.' \
    ' Downtime required in case Rails caches them'

  def up
    %w[ci_application_settings
       ci_events
       ci_jobs
       ci_sessions
       ci_taggings
       ci_tags].each do |table|
      drop_table(table)
    end

    remove_column :ci_pipelines, :push_data, :text
    remove_column :ci_builds, :job_id, :integer if column_exists?(:ci_builds, :job_id)
    remove_column :ci_builds, :deploy, :boolean
  end

  def down
    add_column :ci_builds, :deploy, :boolean
    add_column :ci_builds, :job_id, :integer
    add_column :ci_pipelines, :push_data, :text

    create_table "ci_tags", force: :cascade do |t|
      t.string "name"
      t.integer "taggings_count", default: 0
    end

    create_table "ci_taggings", force: :cascade do |t|
      t.integer "tag_id"
      t.integer "taggable_id"
      t.string "taggable_type"
      t.integer "tagger_id"
      t.string "tagger_type"
      t.string "context", limit: 128
      t.datetime "created_at"
    end

    add_index "ci_taggings", %w[taggable_id taggable_type context]

    create_table "ci_sessions", force: :cascade do |t|
      t.string "session_id", null: false
      t.text "data"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "ci_jobs", force: :cascade do |t|
      t.integer "project_id", null: false
      t.text "commands"
      t.boolean "active", default: true, null: false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string "name"
      t.boolean "build_branches", default: true, null: false
      t.boolean "build_tags", default: false, null: false
      t.string "job_type", default: "parallel"
      t.string "refs"
      t.datetime "deleted_at"
    end

    create_table "ci_events", force: :cascade do |t|
      t.integer "project_id"
      t.integer "user_id"
      t.integer "is_admin"
      t.text "description"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "ci_application_settings", force: :cascade do |t|
      t.boolean "all_broken_builds"
      t.boolean "add_pusher"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
  end
end
