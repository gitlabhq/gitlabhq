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

ActiveRecord::Schema.define(version: 20160610301627) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "pg_trgm"

  create_table "abuse_reports", force: :cascade do |t|
    t.integer  "reporter_id"
    t.integer  "user_id"
    t.text     "message"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "appearances", force: :cascade do |t|
    t.string   "title"
    t.text     "description"
    t.string   "header_logo"
    t.string   "logo"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "application_settings", force: :cascade do |t|
    t.integer  "default_projects_limit"
    t.boolean  "signup_enabled"
    t.boolean  "signin_enabled"
    t.boolean  "gravatar_enabled"
    t.text     "sign_in_text"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "home_page_url"
    t.integer  "default_branch_protection",             default: 2
    t.text     "restricted_visibility_levels"
    t.boolean  "version_check_enabled",                 default: true
    t.integer  "max_attachment_size",                   default: 10,          null: false
    t.integer  "default_project_visibility"
    t.integer  "default_snippet_visibility"
    t.text     "restricted_signup_domains"
    t.boolean  "user_oauth_applications",               default: true
    t.string   "after_sign_out_path"
    t.integer  "session_expire_delay",                  default: 10080,       null: false
    t.text     "import_sources"
    t.text     "help_page_text"
    t.string   "admin_notification_email"
    t.boolean  "shared_runners_enabled",                default: true,        null: false
    t.integer  "max_artifacts_size",                    default: 100,         null: false
    t.string   "runners_registration_token"
    t.boolean  "require_two_factor_authentication",     default: false
    t.integer  "two_factor_grace_period",               default: 48
    t.boolean  "metrics_enabled",                       default: false
    t.string   "metrics_host",                          default: "localhost"
    t.integer  "metrics_pool_size",                     default: 16
    t.integer  "metrics_timeout",                       default: 10
    t.integer  "metrics_method_call_threshold",         default: 10
    t.boolean  "recaptcha_enabled",                     default: false
    t.string   "recaptcha_site_key"
    t.string   "recaptcha_private_key"
    t.integer  "metrics_port",                          default: 8089
    t.boolean  "akismet_enabled",                       default: false
    t.string   "akismet_api_key"
    t.integer  "metrics_sample_interval",               default: 15
    t.boolean  "sentry_enabled",                        default: false
    t.string   "sentry_dsn"
    t.boolean  "email_author_in_body",                  default: false
    t.integer  "default_group_visibility"
    t.boolean  "repository_checks_enabled",             default: false
    t.text     "shared_runners_text"
    t.integer  "metrics_packet_size",                   default: 1
    t.text     "disabled_oauth_sign_in_sources"
    t.string   "health_check_access_token"
    t.boolean  "send_user_confirmation_email",          default: false
    t.integer  "container_registry_token_expire_delay", default: 5
    t.text     "after_sign_up_text"
  end

  create_table "audit_events", force: :cascade do |t|
    t.integer  "author_id",   null: false
    t.string   "type",        null: false
    t.integer  "entity_id",   null: false
    t.string   "entity_type", null: false
    t.text     "details"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "audit_events", ["author_id"], name: "index_audit_events_on_author_id", using: :btree
  add_index "audit_events", ["entity_id", "entity_type"], name: "index_audit_events_on_entity_id_and_entity_type", using: :btree
  add_index "audit_events", ["type"], name: "index_audit_events_on_type", using: :btree

  create_table "award_emoji", force: :cascade do |t|
    t.string   "name"
    t.integer  "user_id"
    t.integer  "awardable_id"
    t.string   "awardable_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "award_emoji", ["awardable_type", "awardable_id"], name: "index_award_emoji_on_awardable_type_and_awardable_id", using: :btree
  add_index "award_emoji", ["user_id"], name: "index_award_emoji_on_user_id", using: :btree

  create_table "broadcast_messages", force: :cascade do |t|
    t.text     "message",    null: false
    t.datetime "starts_at"
    t.datetime "ends_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "color"
    t.string   "font"
  end

  create_table "ci_application_settings", force: :cascade do |t|
    t.boolean  "all_broken_builds"
    t.boolean  "add_pusher"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "ci_builds", force: :cascade do |t|
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
    t.boolean  "deploy",              default: false
    t.text     "options"
    t.boolean  "allow_failure",       default: false, null: false
    t.string   "stage"
    t.integer  "trigger_request_id"
    t.integer  "stage_idx"
    t.boolean  "tag"
    t.string   "ref"
    t.integer  "user_id"
    t.string   "type"
    t.string   "target_url"
    t.string   "description"
    t.text     "artifacts_file"
    t.integer  "gl_project_id"
    t.text     "artifacts_metadata"
    t.integer  "erased_by_id"
    t.datetime "erased_at"
    t.string   "environment"
    t.datetime "artifacts_expire_at"
  end

  add_index "ci_builds", ["commit_id", "stage_idx", "created_at"], name: "index_ci_builds_on_commit_id_and_stage_idx_and_created_at", using: :btree
  add_index "ci_builds", ["commit_id", "status", "type"], name: "index_ci_builds_on_commit_id_and_status_and_type", using: :btree
  add_index "ci_builds", ["commit_id", "type", "name", "ref"], name: "index_ci_builds_on_commit_id_and_type_and_name_and_ref", using: :btree
  add_index "ci_builds", ["commit_id", "type", "ref"], name: "index_ci_builds_on_commit_id_and_type_and_ref", using: :btree
  add_index "ci_builds", ["commit_id"], name: "index_ci_builds_on_commit_id", using: :btree
  add_index "ci_builds", ["erased_by_id"], name: "index_ci_builds_on_erased_by_id", using: :btree
  add_index "ci_builds", ["gl_project_id"], name: "index_ci_builds_on_gl_project_id", using: :btree
  add_index "ci_builds", ["project_id", "commit_id"], name: "index_ci_builds_on_project_id_and_commit_id", using: :btree
  add_index "ci_builds", ["project_id"], name: "index_ci_builds_on_project_id", using: :btree
  add_index "ci_builds", ["runner_id"], name: "index_ci_builds_on_runner_id", using: :btree
  add_index "ci_builds", ["status"], name: "index_ci_builds_on_status", using: :btree
  add_index "ci_builds", ["type"], name: "index_ci_builds_on_type", using: :btree

  create_table "ci_commits", force: :cascade do |t|
    t.integer  "project_id"
    t.string   "ref"
    t.string   "sha"
    t.string   "before_sha"
    t.text     "push_data"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "tag",           default: false
    t.text     "yaml_errors"
    t.datetime "committed_at"
    t.integer  "gl_project_id"
    t.string   "status"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.integer  "duration"
  end

  add_index "ci_commits", ["gl_project_id", "sha"], name: "index_ci_commits_on_gl_project_id_and_sha", using: :btree
  add_index "ci_commits", ["gl_project_id", "status"], name: "index_ci_commits_on_gl_project_id_and_status", using: :btree
  add_index "ci_commits", ["gl_project_id"], name: "index_ci_commits_on_gl_project_id", using: :btree
  add_index "ci_commits", ["project_id", "committed_at", "id"], name: "index_ci_commits_on_project_id_and_committed_at_and_id", using: :btree
  add_index "ci_commits", ["project_id", "committed_at"], name: "index_ci_commits_on_project_id_and_committed_at", using: :btree
  add_index "ci_commits", ["project_id", "sha"], name: "index_ci_commits_on_project_id_and_sha", using: :btree
  add_index "ci_commits", ["project_id"], name: "index_ci_commits_on_project_id", using: :btree
  add_index "ci_commits", ["sha"], name: "index_ci_commits_on_sha", using: :btree
  add_index "ci_commits", ["status"], name: "index_ci_commits_on_status", using: :btree

  create_table "ci_events", force: :cascade do |t|
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

  create_table "ci_jobs", force: :cascade do |t|
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

  create_table "ci_projects", force: :cascade do |t|
    t.string   "name"
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

  add_index "ci_projects", ["gitlab_id"], name: "index_ci_projects_on_gitlab_id", using: :btree
  add_index "ci_projects", ["shared_runners_enabled"], name: "index_ci_projects_on_shared_runners_enabled", using: :btree

  create_table "ci_runner_projects", force: :cascade do |t|
    t.integer  "runner_id",     null: false
    t.integer  "project_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "gl_project_id"
  end

  add_index "ci_runner_projects", ["gl_project_id"], name: "index_ci_runner_projects_on_gl_project_id", using: :btree
  add_index "ci_runner_projects", ["runner_id"], name: "index_ci_runner_projects_on_runner_id", using: :btree

  create_table "ci_runners", force: :cascade do |t|
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
    t.boolean  "run_untagged", default: true,  null: false
  end

  add_index "ci_runners", ["description"], name: "index_ci_runners_on_description_trigram", using: :gin, opclasses: {"description"=>"gin_trgm_ops"}
  add_index "ci_runners", ["token"], name: "index_ci_runners_on_token", using: :btree
  add_index "ci_runners", ["token"], name: "index_ci_runners_on_token_trigram", using: :gin, opclasses: {"token"=>"gin_trgm_ops"}

  create_table "ci_services", force: :cascade do |t|
    t.string   "type"
    t.string   "title"
    t.integer  "project_id",                 null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "active",     default: false, null: false
    t.text     "properties"
  end

  add_index "ci_services", ["project_id"], name: "index_ci_services_on_project_id", using: :btree

  create_table "ci_sessions", force: :cascade do |t|
    t.string   "session_id", null: false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "ci_sessions", ["session_id"], name: "index_ci_sessions_on_session_id", using: :btree
  add_index "ci_sessions", ["updated_at"], name: "index_ci_sessions_on_updated_at", using: :btree

  create_table "ci_taggings", force: :cascade do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type"
    t.integer  "tagger_id"
    t.string   "tagger_type"
    t.string   "context",       limit: 128
    t.datetime "created_at"
  end

  add_index "ci_taggings", ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "ci_taggings_idx", unique: true, using: :btree
  add_index "ci_taggings", ["taggable_id", "taggable_type", "context"], name: "index_ci_taggings_on_taggable_id_and_taggable_type_and_context", using: :btree

  create_table "ci_tags", force: :cascade do |t|
    t.string  "name"
    t.integer "taggings_count", default: 0
  end

  add_index "ci_tags", ["name"], name: "index_ci_tags_on_name", unique: true, using: :btree

  create_table "ci_trigger_requests", force: :cascade do |t|
    t.integer  "trigger_id", null: false
    t.text     "variables"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "commit_id"
  end

  create_table "ci_triggers", force: :cascade do |t|
    t.string   "token"
    t.integer  "project_id"
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "gl_project_id"
  end

  add_index "ci_triggers", ["deleted_at"], name: "index_ci_triggers_on_deleted_at", using: :btree
  add_index "ci_triggers", ["gl_project_id"], name: "index_ci_triggers_on_gl_project_id", using: :btree

  create_table "ci_variables", force: :cascade do |t|
    t.integer "project_id"
    t.string  "key"
    t.text    "value"
    t.text    "encrypted_value"
    t.string  "encrypted_value_salt"
    t.string  "encrypted_value_iv"
    t.integer "gl_project_id"
  end

  add_index "ci_variables", ["gl_project_id"], name: "index_ci_variables_on_gl_project_id", using: :btree

  create_table "ci_web_hooks", force: :cascade do |t|
    t.string   "url",        null: false
    t.integer  "project_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "deploy_keys_projects", force: :cascade do |t|
    t.integer  "deploy_key_id", null: false
    t.integer  "project_id",    null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "deploy_keys_projects", ["project_id"], name: "index_deploy_keys_projects_on_project_id", using: :btree

  create_table "deployments", force: :cascade do |t|
    t.integer  "iid",             null: false
    t.integer  "project_id",      null: false
    t.integer  "environment_id",  null: false
    t.string   "ref",             null: false
    t.boolean  "tag",             null: false
    t.string   "sha",             null: false
    t.integer  "user_id"
    t.integer  "deployable_id"
    t.string   "deployable_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "deployments", ["project_id", "environment_id", "iid"], name: "index_deployments_on_project_id_and_environment_id_and_iid", using: :btree
  add_index "deployments", ["project_id", "environment_id"], name: "index_deployments_on_project_id_and_environment_id", using: :btree
  add_index "deployments", ["project_id", "iid"], name: "index_deployments_on_project_id_and_iid", using: :btree
  add_index "deployments", ["project_id"], name: "index_deployments_on_project_id", using: :btree

  create_table "emails", force: :cascade do |t|
    t.integer  "user_id",    null: false
    t.string   "email",      null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "emails", ["email"], name: "index_emails_on_email", unique: true, using: :btree
  add_index "emails", ["user_id"], name: "index_emails_on_user_id", using: :btree

  create_table "environments", force: :cascade do |t|
    t.integer  "project_id"
    t.string   "name",       null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "environments", ["project_id", "name"], name: "index_environments_on_project_id_and_name", using: :btree

  create_table "events", force: :cascade do |t|
    t.string   "target_type"
    t.integer  "target_id"
    t.string   "title"
    t.text     "data"
    t.integer  "project_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "action"
    t.integer  "author_id"
  end

  add_index "events", ["action"], name: "index_events_on_action", using: :btree
  add_index "events", ["author_id"], name: "index_events_on_author_id", using: :btree
  add_index "events", ["created_at"], name: "index_events_on_created_at", using: :btree
  add_index "events", ["project_id"], name: "index_events_on_project_id", using: :btree
  add_index "events", ["target_id"], name: "index_events_on_target_id", using: :btree
  add_index "events", ["target_type"], name: "index_events_on_target_type", using: :btree

  create_table "forked_project_links", force: :cascade do |t|
    t.integer  "forked_to_project_id",   null: false
    t.integer  "forked_from_project_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "forked_project_links", ["forked_to_project_id"], name: "index_forked_project_links_on_forked_to_project_id", unique: true, using: :btree

  create_table "identities", force: :cascade do |t|
    t.string   "extern_uid"
    t.string   "provider"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "identities", ["created_at", "id"], name: "index_identities_on_created_at_and_id", using: :btree
  add_index "identities", ["user_id"], name: "index_identities_on_user_id", using: :btree

  create_table "issues", force: :cascade do |t|
    t.string   "title"
    t.integer  "assignee_id"
    t.integer  "author_id"
    t.integer  "project_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "position",      default: 0
    t.string   "branch_name"
    t.text     "description"
    t.integer  "milestone_id"
    t.string   "state"
    t.integer  "iid"
    t.integer  "updated_by_id"
    t.boolean  "confidential",  default: false
    t.datetime "deleted_at"
    t.date     "due_date"
    t.integer  "moved_to_id"
  end

  add_index "issues", ["assignee_id"], name: "index_issues_on_assignee_id", using: :btree
  add_index "issues", ["author_id"], name: "index_issues_on_author_id", using: :btree
  add_index "issues", ["confidential"], name: "index_issues_on_confidential", using: :btree
  add_index "issues", ["created_at", "id"], name: "index_issues_on_created_at_and_id", using: :btree
  add_index "issues", ["created_at"], name: "index_issues_on_created_at", using: :btree
  add_index "issues", ["deleted_at"], name: "index_issues_on_deleted_at", using: :btree
  add_index "issues", ["description"], name: "index_issues_on_description_trigram", using: :gin, opclasses: {"description"=>"gin_trgm_ops"}
  add_index "issues", ["due_date"], name: "index_issues_on_due_date", using: :btree
  add_index "issues", ["milestone_id"], name: "index_issues_on_milestone_id", using: :btree
  add_index "issues", ["project_id", "iid"], name: "index_issues_on_project_id_and_iid", unique: true, using: :btree
  add_index "issues", ["project_id"], name: "index_issues_on_project_id", using: :btree
  add_index "issues", ["state"], name: "index_issues_on_state", using: :btree
  add_index "issues", ["title"], name: "index_issues_on_title", using: :btree
  add_index "issues", ["title"], name: "index_issues_on_title_trigram", using: :gin, opclasses: {"title"=>"gin_trgm_ops"}

  create_table "keys", force: :cascade do |t|
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "key"
    t.string   "title"
    t.string   "type"
    t.string   "fingerprint"
    t.boolean  "public",      default: false, null: false
  end

  add_index "keys", ["created_at", "id"], name: "index_keys_on_created_at_and_id", using: :btree
  add_index "keys", ["user_id"], name: "index_keys_on_user_id", using: :btree

  create_table "label_links", force: :cascade do |t|
    t.integer  "label_id"
    t.integer  "target_id"
    t.string   "target_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "label_links", ["label_id"], name: "index_label_links_on_label_id", using: :btree
  add_index "label_links", ["target_id", "target_type"], name: "index_label_links_on_target_id_and_target_type", using: :btree

  create_table "labels", force: :cascade do |t|
    t.string   "title"
    t.string   "color"
    t.integer  "project_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "template",    default: false
    t.string   "description"
    t.integer  "priority"
  end

  add_index "labels", ["priority"], name: "index_labels_on_priority", using: :btree
  add_index "labels", ["project_id"], name: "index_labels_on_project_id", using: :btree

  create_table "lfs_objects", force: :cascade do |t|
    t.string   "oid",                  null: false
    t.integer  "size",       limit: 8, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "file"
  end

  add_index "lfs_objects", ["oid"], name: "index_lfs_objects_on_oid", unique: true, using: :btree

  create_table "lfs_objects_projects", force: :cascade do |t|
    t.integer  "lfs_object_id", null: false
    t.integer  "project_id",    null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "lfs_objects_projects", ["project_id"], name: "index_lfs_objects_projects_on_project_id", using: :btree

  create_table "members", force: :cascade do |t|
    t.integer  "access_level",       null: false
    t.integer  "source_id",          null: false
    t.string   "source_type",        null: false
    t.integer  "user_id"
    t.integer  "notification_level", null: false
    t.string   "type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "created_by_id"
    t.string   "invite_email"
    t.string   "invite_token"
    t.datetime "invite_accepted_at"
  end

  add_index "members", ["access_level"], name: "index_members_on_access_level", using: :btree
  add_index "members", ["created_at", "id"], name: "index_members_on_created_at_and_id", using: :btree
  add_index "members", ["invite_token"], name: "index_members_on_invite_token", unique: true, using: :btree
  add_index "members", ["source_id", "source_type"], name: "index_members_on_source_id_and_source_type", using: :btree
  add_index "members", ["type"], name: "index_members_on_type", using: :btree
  add_index "members", ["user_id"], name: "index_members_on_user_id", using: :btree

  create_table "merge_request_diffs", force: :cascade do |t|
    t.string   "state"
    t.text     "st_commits"
    t.text     "st_diffs"
    t.integer  "merge_request_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "base_commit_sha"
    t.string   "real_size"
  end

  add_index "merge_request_diffs", ["merge_request_id"], name: "index_merge_request_diffs_on_merge_request_id", unique: true, using: :btree

  create_table "merge_requests", force: :cascade do |t|
    t.string   "target_branch",                             null: false
    t.string   "source_branch",                             null: false
    t.integer  "source_project_id",                         null: false
    t.integer  "author_id"
    t.integer  "assignee_id"
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "milestone_id"
    t.string   "state"
    t.string   "merge_status"
    t.integer  "target_project_id",                         null: false
    t.integer  "iid"
    t.text     "description"
    t.integer  "position",                  default: 0
    t.datetime "locked_at"
    t.integer  "updated_by_id"
    t.string   "merge_error"
    t.text     "merge_params"
    t.boolean  "merge_when_build_succeeds", default: false, null: false
    t.integer  "merge_user_id"
    t.string   "merge_commit_sha"
    t.datetime "deleted_at"
  end

  add_index "merge_requests", ["assignee_id"], name: "index_merge_requests_on_assignee_id", using: :btree
  add_index "merge_requests", ["author_id"], name: "index_merge_requests_on_author_id", using: :btree
  add_index "merge_requests", ["created_at", "id"], name: "index_merge_requests_on_created_at_and_id", using: :btree
  add_index "merge_requests", ["created_at"], name: "index_merge_requests_on_created_at", using: :btree
  add_index "merge_requests", ["deleted_at"], name: "index_merge_requests_on_deleted_at", using: :btree
  add_index "merge_requests", ["description"], name: "index_merge_requests_on_description_trigram", using: :gin, opclasses: {"description"=>"gin_trgm_ops"}
  add_index "merge_requests", ["milestone_id"], name: "index_merge_requests_on_milestone_id", using: :btree
  add_index "merge_requests", ["source_branch"], name: "index_merge_requests_on_source_branch", using: :btree
  add_index "merge_requests", ["source_project_id"], name: "index_merge_requests_on_source_project_id", using: :btree
  add_index "merge_requests", ["target_branch"], name: "index_merge_requests_on_target_branch", using: :btree
  add_index "merge_requests", ["target_project_id", "iid"], name: "index_merge_requests_on_target_project_id_and_iid", unique: true, using: :btree
  add_index "merge_requests", ["title"], name: "index_merge_requests_on_title", using: :btree
  add_index "merge_requests", ["title"], name: "index_merge_requests_on_title_trigram", using: :gin, opclasses: {"title"=>"gin_trgm_ops"}

