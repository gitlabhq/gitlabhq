# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20180331055706) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "event_log_states", primary_key: "event_id", force: :cascade do |t|
  end

  create_table "file_registry", force: :cascade do |t|
    t.string "file_type", null: false
    t.integer "file_id", null: false
    t.integer "bytes", limit: 8
    t.string "sha256"
    t.datetime "created_at", null: false
    t.boolean "success", default: false, null: false
    t.integer "retry_count"
    t.datetime "retry_at"
  end

  add_index "file_registry", ["file_type", "file_id"], name: "index_file_registry_on_file_type_and_file_id", unique: true, using: :btree
  add_index "file_registry", ["file_type"], name: "index_file_registry_on_file_type", using: :btree
  add_index "file_registry", ["retry_at"], name: "index_file_registry_on_retry_at", using: :btree
  add_index "file_registry", ["success"], name: "index_file_registry_on_success", using: :btree

  create_table "job_artifact_registry", force: :cascade do |t|
    t.datetime_with_timezone "created_at"
    t.datetime_with_timezone "retry_at"
    t.integer "bytes", limit: 8
    t.integer "artifact_id"
    t.integer "retry_count"
    t.boolean "success"
    t.string "sha256"
  end

  add_index "job_artifact_registry", ["retry_at"], name: "index_job_artifact_registry_on_retry_at", using: :btree
  add_index "job_artifact_registry", ["success"], name: "index_job_artifact_registry_on_success", using: :btree

  create_table "project_registry", force: :cascade do |t|
    t.integer "project_id", null: false
    t.datetime "last_repository_synced_at"
    t.datetime "last_repository_successful_sync_at"
    t.datetime "created_at", null: false
    t.boolean "resync_repository", default: true, null: false
    t.boolean "resync_wiki", default: true, null: false
    t.datetime "last_wiki_synced_at"
    t.datetime "last_wiki_successful_sync_at"
    t.integer "repository_retry_count"
    t.datetime "repository_retry_at"
    t.boolean "force_to_redownload_repository"
    t.integer "wiki_retry_count"
    t.datetime "wiki_retry_at"
    t.boolean "force_to_redownload_wiki"
    t.string "last_repository_sync_failure"
    t.string "last_wiki_sync_failure"
    t.string "repository_verification_checksum"
    t.string "last_repository_verification_failure"
    t.string "wiki_verification_checksum"
    t.string "last_wiki_verification_failure"
  end

  add_index "project_registry", ["last_repository_successful_sync_at"], name: "index_project_registry_on_last_repository_successful_sync_at", using: :btree
  add_index "project_registry", ["last_repository_synced_at"], name: "index_project_registry_on_last_repository_synced_at", using: :btree
  add_index "project_registry", ["project_id"], name: "idx_project_registry_on_repository_failure_partial", where: "(last_repository_verification_failure IS NOT NULL)", using: :btree
  add_index "project_registry", ["project_id"], name: "idx_project_registry_on_wiki_failure_partial", where: "(last_wiki_verification_failure IS NOT NULL)", using: :btree
  add_index "project_registry", ["project_id"], name: "index_project_registry_on_project_id", unique: true, using: :btree
  add_index "project_registry", ["repository_retry_at"], name: "index_project_registry_on_repository_retry_at", using: :btree
  add_index "project_registry", ["repository_verification_checksum"], name: "idx_project_registry_on_repository_checksum_partial", where: "(repository_verification_checksum IS NULL)", using: :btree
  add_index "project_registry", ["resync_repository"], name: "index_project_registry_on_resync_repository", using: :btree
  add_index "project_registry", ["resync_wiki"], name: "index_project_registry_on_resync_wiki", using: :btree
  add_index "project_registry", ["wiki_retry_at"], name: "index_project_registry_on_wiki_retry_at", using: :btree
  add_index "project_registry", ["wiki_verification_checksum"], name: "idx_project_registry_on_wiki_checksum_partial", where: "(wiki_verification_checksum IS NULL)", using: :btree

end
