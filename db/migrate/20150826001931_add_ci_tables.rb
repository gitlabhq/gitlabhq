class AddCiTables < ActiveRecord::Migration
  def change
    create_table "ci_application_settings", force: true do |t|
      t.boolean  "all_broken_builds"
      t.boolean  "add_pusher"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "ci_builds", force: true do |t|
      t.integer  "project_id"
      t.string   "status"
      t.datetime "finished_at"
      t.text     "trace"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.datetime "started_at"
      t.integer  "runner_id"
      t.float    "coverage"
      t.integer  "commit_id"
      t.text     "commands"
      t.integer  "job_id"
      t.string   "name"
      t.boolean  "deploy",             default: false
      t.text     "options"
      t.boolean  "allow_failure",      default: false, null: false
      t.string   "stage"
      t.integer  "trigger_request_id"
    end

    add_index "ci_builds", ["commit_id"], name: "index_ci_builds_on_commit_id", using: :btree
    add_index "ci_builds", ["project_id", "commit_id"], name: "index_ci_builds_on_project_id_and_commit_id", using: :btree
    add_index "ci_builds", ["project_id"], name: "index_ci_builds_on_project_id", using: :btree
    add_index "ci_builds", ["runner_id"], name: "index_ci_builds_on_runner_id", using: :btree

    create_table "ci_commits", force: true do |t|
      t.integer  "project_id"
      t.string   "ref"
      t.string   "sha"
      t.string   "before_sha"
      t.text     "push_data"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.boolean  "tag",          default: false
      t.text     "yaml_errors"
      t.datetime "committed_at"
    end

    add_index "ci_commits", ["project_id", "committed_at"], name: "index_ci_commits_on_project_id_and_committed_at", using: :btree
    add_index "ci_commits", ["project_id", "sha"], name: "index_ci_commits_on_project_id_and_sha", using: :btree
    add_index "ci_commits", ["project_id"], name: "index_ci_commits_on_project_id", using: :btree
    add_index "ci_commits", ["sha"], name: "index_ci_commits_on_sha", using: :btree

    create_table "ci_events", force: true do |t|
      t.integer  "project_id"
      t.integer  "user_id"
      t.integer  "is_admin"
      t.text     "description"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "ci_events", ["created_at"], name: "index_ci_events_on_created_at", using: :btree
    add_index "ci_events", ["is_admin"], name: "index_ci_events_on_is_admin", using: :btree
    add_index "ci_events", ["project_id"], name: "index_ci_events_on_project_id", using: :btree

    create_table "ci_jobs", force: true do |t|
      t.integer  "project_id",                          null: false
      t.text     "commands"
      t.boolean  "active",         default: true,       null: false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "name"
      t.boolean  "build_branches", default: true,       null: false
      t.boolean  "build_tags",     default: false,      null: false
      t.string   "job_type",       default: "parallel"
      t.string   "refs"
      t.datetime "deleted_at"
    end

    add_index "ci_jobs", ["deleted_at"], name: "index_ci_jobs_on_deleted_at", using: :btree
    add_index "ci_jobs", ["project_id"], name: "index_ci_jobs_on_project_id", using: :btree

    create_table "ci_projects", force: true do |t|
      t.string   "name",                                     null: false
      t.integer  "timeout",                  default: 3600,  null: false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "token"
      t.string   "default_ref"
      t.string   "path"
      t.boolean  "always_build",             default: false, null: false
      t.integer  "polling_interval"
      t.boolean  "public",                   default: false, null: false
      t.string   "ssh_url_to_repo"
      t.integer  "gitlab_id"
      t.boolean  "allow_git_fetch",          default: true,  null: false
      t.string   "email_recipients",         default: "",    null: false
      t.boolean  "email_add_pusher",         default: true,  null: false
      t.boolean  "email_only_broken_builds", default: true,  null: false
      t.string   "skip_refs"
      t.string   "coverage_regex"
      t.boolean  "shared_runners_enabled",   default: false
      t.text     "generated_yaml_config"
    end

    create_table "ci_runner_projects", force: true do |t|
      t.integer  "runner_id",  null: false
      t.integer  "project_id", null: false
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "ci_runner_projects", ["project_id"], name: "index_ci_runner_projects_on_project_id", using: :btree
    add_index "ci_runner_projects", ["runner_id"], name: "index_ci_runner_projects_on_runner_id", using: :btree

    create_table "ci_runners", force: true do |t|
      t.string   "token"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "description"
      t.datetime "contacted_at"
      t.boolean  "active",       default: true,  null: false
      t.boolean  "is_shared",    default: false
      t.string   "name"
      t.string   "version"
      t.string   "revision"
      t.string   "platform"
      t.string   "architecture"
    end

    create_table "ci_services", force: true do |t|
      t.string   "type"
      t.string   "title"
      t.integer  "project_id",                 null: false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.boolean  "active",     default: false, null: false
      t.text     "properties"
    end

    add_index "ci_services", ["project_id"], name: "index_ci_services_on_project_id", using: :btree

    create_table "ci_sessions", force: true do |t|
      t.string   "session_id", null: false
      t.text     "data"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "ci_sessions", ["session_id"], name: "index_ci_sessions_on_session_id", using: :btree
    add_index "ci_sessions", ["updated_at"], name: "index_ci_sessions_on_updated_at", using: :btree

    create_table "ci_trigger_requests", force: true do |t|
      t.integer  "trigger_id", null: false
      t.text     "variables"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "commit_id"
    end

    create_table "ci_triggers", force: true do |t|
      t.string   "token"
      t.integer  "project_id", null: false
      t.datetime "deleted_at"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "ci_triggers", ["deleted_at"], name: "index_ci_triggers_on_deleted_at", using: :btree

    create_table "ci_variables", force: true do |t|
      t.integer "project_id",           null: false
      t.string  "key"
      t.text    "value"
      t.text    "encrypted_value"
      t.string  "encrypted_value_salt"
      t.string  "encrypted_value_iv"
    end

    add_index "ci_variables", ["project_id"], name: "index_ci_variables_on_project_id", using: :btree

    create_table "ci_web_hooks", force: true do |t|
      t.string   "url",        null: false
      t.integer  "project_id", null: false
      t.datetime "created_at"
      t.datetime "updated_at"
    end
  end
end
