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

ActiveRecord::Schema.define(version: 20161109150329) do

  create_table "abuse_reports", force: :cascade do |t|
    t.integer "reporter_id", limit: 4
    t.integer "user_id", limit: 4
    t.text "message", limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "message_html", limit: 65535
  end

  create_table "appearances", force: :cascade do |t|
    t.string "title", limit: 255
    t.text "description", limit: 65535
    t.string "logo", limit: 255
    t.integer "updated_by", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "header_logo", limit: 255
    t.text "description_html", limit: 65535
  end

  create_table "application_settings", force: :cascade do |t|
    t.integer "default_projects_limit", limit: 4
    t.boolean "signup_enabled"
    t.boolean "signin_enabled"
    t.boolean "gravatar_enabled"
    t.text "sign_in_text", limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "home_page_url", limit: 255
    t.integer "default_branch_protection", limit: 4, default: 2
    t.text "help_text", limit: 65535
    t.text "restricted_visibility_levels", limit: 65535
    t.boolean "version_check_enabled", default: true
    t.integer "max_attachment_size", limit: 4, default: 10, null: false
    t.integer "default_project_visibility", limit: 4
    t.integer "default_snippet_visibility", limit: 4
    t.text "domain_whitelist", limit: 65535
    t.boolean "user_oauth_applications", default: true
    t.string "after_sign_out_path", limit: 255
    t.integer "session_expire_delay", limit: 4, default: 10080, null: false
    t.text "import_sources", limit: 65535
    t.text "help_page_text", limit: 65535
    t.string "admin_notification_email", limit: 255
    t.boolean "shared_runners_enabled", default: true, null: false
    t.integer "max_artifacts_size", limit: 4, default: 100, null: false
    t.string "runners_registration_token", limit: 255
    t.integer "max_pages_size", limit: 4, default: 100, null: false
    t.boolean "require_two_factor_authentication", default: false
    t.integer "two_factor_grace_period", limit: 4, default: 48
    t.boolean "metrics_enabled", default: false
    t.string "metrics_host", limit: 255, default: "localhost"
    t.integer "metrics_pool_size", limit: 4, default: 16
    t.integer "metrics_timeout", limit: 4, default: 10
    t.integer "metrics_method_call_threshold", limit: 4, default: 10
    t.boolean "recaptcha_enabled", default: false
    t.string "recaptcha_site_key", limit: 255
    t.string "recaptcha_private_key", limit: 255
    t.integer "metrics_port", limit: 4, default: 8089
    t.boolean "akismet_enabled", default: false
    t.string "akismet_api_key", limit: 255
    t.integer "metrics_sample_interval", limit: 4, default: 15
    t.boolean "sentry_enabled", default: false
    t.string "sentry_dsn", limit: 255
    t.boolean "email_author_in_body", default: false
    t.integer "default_group_visibility", limit: 4
    t.boolean "repository_checks_enabled", default: false
    t.text "shared_runners_text", limit: 65535
    t.integer "metrics_packet_size", limit: 4, default: 1
    t.text "disabled_oauth_sign_in_sources", limit: 65535
    t.string "health_check_access_token", limit: 255
    t.boolean "send_user_confirmation_email", default: false
    t.integer "container_registry_token_expire_delay", limit: 4, default: 5
    t.text "after_sign_up_text", limit: 65535
    t.boolean "user_default_external", default: false, null: false
    t.boolean "elasticsearch_indexing", default: false, null: false
    t.boolean "elasticsearch_search", default: false, null: false
    t.string "elasticsearch_host", limit: 255, default: "localhost"
    t.string "elasticsearch_port", limit: 255, default: "9200"
    t.string "repository_storages", limit: 255, default: "default"
    t.string "enabled_git_access_protocol", limit: 255
    t.boolean "domain_blacklist_enabled", default: false
    t.text "domain_blacklist", limit: 65535
    t.boolean "usage_ping_enabled", default: true, null: false
    t.boolean "koding_enabled"
    t.string "koding_url", limit: 255
    t.integer "repository_size_limit", limit: 4, default: 0
    t.text "sign_in_text_html", limit: 65535
    t.text "help_page_text_html", limit: 65535
    t.text "shared_runners_text_html", limit: 65535
    t.text "after_sign_up_text_html", limit: 65535
    t.boolean "user_activity_enabled", default: true, null: false
    t.boolean "housekeeping_enabled", default: true, null: false
    t.boolean "housekeeping_bitmaps_enabled", default: true, null: false
    t.integer "housekeeping_incremental_repack_period", limit: 4, default: 10, null: false
    t.integer "housekeeping_full_repack_period", limit: 4, default: 50, null: false
    t.integer "housekeeping_gc_period", limit: 4, default: 200, null: false
    t.boolean "sidekiq_throttling_enabled", default: false
    t.string "sidekiq_throttling_queues", limit: 255
    t.decimal "sidekiq_throttling_factor", precision: 10
  end

  create_table "approvals", force: :cascade do |t|
    t.integer "merge_request_id", limit: 4, null: false
    t.integer "user_id", limit: 4, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "approver_groups", force: :cascade do |t|
    t.integer "target_id", limit: 4, null: false
    t.string "target_type", limit: 255, null: false
    t.integer "group_id", limit: 4, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "approver_groups", ["group_id"], name: "index_approver_groups_on_group_id", using: :btree
  add_index "approver_groups", ["target_id", "target_type"], name: "index_approver_groups_on_target_id_and_target_type", using: :btree

  create_table "approvers", force: :cascade do |t|
    t.integer "target_id", limit: 4, null: false
    t.string "target_type", limit: 255
    t.integer "user_id", limit: 4, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "approvers", ["target_id", "target_type"], name: "index_approvers_on_target_id_and_target_type", using: :btree
  add_index "approvers", ["user_id"], name: "index_approvers_on_user_id", using: :btree

  create_table "audit_events", force: :cascade do |t|
    t.integer "author_id", limit: 4, null: false
    t.string "type", limit: 255, null: false
    t.integer "entity_id", limit: 4, null: false
    t.string "entity_type", limit: 255, null: false
    t.text "details", limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "audit_events", ["entity_id", "entity_type"], name: "index_audit_events_on_entity_id_and_entity_type", using: :btree

  create_table "award_emoji", force: :cascade do |t|
    t.string "name", limit: 255
    t.integer "user_id", limit: 4
    t.integer "awardable_id", limit: 4
    t.string "awardable_type", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "award_emoji", ["awardable_type", "awardable_id"], name: "index_award_emoji_on_awardable_type_and_awardable_id", using: :btree
  add_index "award_emoji", ["user_id", "name"], name: "index_award_emoji_on_user_id_and_name", using: :btree
  add_index "award_emoji", ["user_id"], name: "index_award_emoji_on_user_id", using: :btree

  create_table "boards", force: :cascade do |t|
    t.integer "project_id", limit: 4, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name", limit: 255, default: "Development", null: false
  end

  add_index "boards", ["project_id"], name: "index_boards_on_project_id", using: :btree

  create_table "broadcast_messages", force: :cascade do |t|
    t.text "message", limit: 65535, null: false
    t.datetime "starts_at"
    t.datetime "ends_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "color", limit: 255
    t.string "font", limit: 255
    t.text "message_html", limit: 65535
  end

  create_table "ci_application_settings", force: :cascade do |t|
    t.boolean "all_broken_builds"
    t.boolean "add_pusher"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "ci_builds", force: :cascade do |t|
    t.integer "project_id", limit: 4
    t.string "status", limit: 255
    t.datetime "finished_at"
    t.text "trace", limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "started_at"
    t.integer "runner_id", limit: 4
    t.float "coverage", limit: 24
    t.integer "commit_id", limit: 4
    t.text "commands", limit: 65535
    t.integer "job_id", limit: 4
    t.string "name", limit: 255
    t.boolean "deploy", default: false
    t.text "options", limit: 65535
    t.boolean "allow_failure", default: false, null: false
    t.string "stage", limit: 255
    t.integer "trigger_request_id", limit: 4
    t.integer "stage_idx", limit: 4
    t.boolean "tag"
    t.string "ref", limit: 255
    t.integer "user_id", limit: 4
    t.string "type", limit: 255
    t.string "target_url", limit: 255
    t.string "description", limit: 255
    t.text "artifacts_file", limit: 65535
    t.integer "gl_project_id", limit: 4
    t.text "artifacts_metadata", limit: 65535
    t.integer "erased_by_id", limit: 4
    t.datetime "erased_at"
    t.datetime "artifacts_expire_at"
    t.string "environment", limit: 255
    t.integer "artifacts_size", limit: 8
    t.string "when", limit: 255
    t.text "yaml_variables", limit: 65535
    t.datetime "queued_at"
    t.string "token", limit: 255
    t.integer "lock_version", limit: 4
  end

  add_index "ci_builds", ["commit_id", "stage_idx", "created_at"], name: "index_ci_builds_on_commit_id_and_stage_idx_and_created_at", using: :btree
  add_index "ci_builds", ["commit_id", "status", "type"], name: "index_ci_builds_on_commit_id_and_status_and_type", using: :btree
  add_index "ci_builds", ["commit_id", "type", "name", "ref"], name: "index_ci_builds_on_commit_id_and_type_and_name_and_ref", using: :btree
  add_index "ci_builds", ["commit_id", "type", "ref"], name: "index_ci_builds_on_commit_id_and_type_and_ref", using: :btree
  add_index "ci_builds", ["commit_id"], name: "index_ci_builds_on_commit_id", using: :btree
  add_index "ci_builds", ["gl_project_id"], name: "index_ci_builds_on_gl_project_id", using: :btree
  add_index "ci_builds", ["project_id"], name: "index_ci_builds_on_project_id", using: :btree
  add_index "ci_builds", ["runner_id"], name: "index_ci_builds_on_runner_id", using: :btree
  add_index "ci_builds", ["status"], name: "index_ci_builds_on_status", using: :btree
  add_index "ci_builds", ["token"], name: "index_ci_builds_on_token", unique: true, using: :btree

  create_table "ci_commits", force: :cascade do |t|
    t.integer "project_id", limit: 4
    t.string "ref", limit: 255
    t.string "sha", limit: 255
    t.string "before_sha", limit: 255
    t.text "push_data", limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "tag", default: false
    t.text "yaml_errors", limit: 65535
    t.datetime "committed_at"
    t.integer "gl_project_id", limit: 4
    t.string "status", limit: 255
    t.datetime "started_at"
    t.datetime "finished_at"
    t.integer "duration", limit: 4
    t.integer "user_id", limit: 4
    t.integer "lock_version", limit: 4
  end

  add_index "ci_commits", ["gl_project_id", "sha"], name: "index_ci_commits_on_gl_project_id_and_sha", using: :btree
  add_index "ci_commits", ["gl_project_id", "status"], name: "index_ci_commits_on_gl_project_id_and_status", using: :btree
  add_index "ci_commits", ["gl_project_id"], name: "index_ci_commits_on_gl_project_id", using: :btree
  add_index "ci_commits", ["status"], name: "index_ci_commits_on_status", using: :btree
  add_index "ci_commits", ["user_id"], name: "index_ci_commits_on_user_id", using: :btree

  create_table "ci_events", force: :cascade do |t|
    t.integer "project_id", limit: 4
    t.integer "user_id", limit: 4
    t.integer "is_admin", limit: 4
    t.text "description", limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "ci_jobs", force: :cascade do |t|
    t.integer "project_id", limit: 4, null: false
    t.text "commands", limit: 65535
    t.boolean "active", default: true, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "name", limit: 255
    t.boolean "build_branches", default: true, null: false
    t.boolean "build_tags", default: false, null: false
    t.string "job_type", limit: 255, default: "parallel"
    t.string "refs", limit: 255
    t.datetime "deleted_at"
  end

  create_table "ci_projects", force: :cascade do |t|
    t.string "name", limit: 255
    t.integer "timeout", limit: 4, default: 3600, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "token", limit: 255
    t.string "default_ref", limit: 255
    t.string "path", limit: 255
    t.boolean "always_build", default: false, null: false
    t.integer "polling_interval", limit: 4
    t.boolean "public", default: false, null: false
    t.string "ssh_url_to_repo", limit: 255
    t.integer "gitlab_id", limit: 4
    t.boolean "allow_git_fetch", default: true, null: false
    t.string "email_recipients", limit: 255, default: "", null: false
    t.boolean "email_add_pusher", default: true, null: false
    t.boolean "email_only_broken_builds", default: true, null: false
    t.string "skip_refs", limit: 255
    t.string "coverage_regex", limit: 255
    t.boolean "shared_runners_enabled", default: false
    t.text "generated_yaml_config", limit: 65535
  end

  create_table "ci_runner_projects", force: :cascade do |t|
    t.integer "runner_id", limit: 4, null: false
    t.integer "project_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "gl_project_id", limit: 4
  end

  add_index "ci_runner_projects", ["gl_project_id"], name: "index_ci_runner_projects_on_gl_project_id", using: :btree
  add_index "ci_runner_projects", ["runner_id"], name: "index_ci_runner_projects_on_runner_id", using: :btree

  create_table "ci_runners", force: :cascade do |t|
    t.string "token", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "description", limit: 255
    t.datetime "contacted_at"
    t.boolean "active", default: true, null: false
    t.boolean "is_shared", default: false
    t.string "name", limit: 255
    t.string "version", limit: 255
    t.string "revision", limit: 255
    t.string "platform", limit: 255
    t.string "architecture", limit: 255
    t.boolean "run_untagged", default: true, null: false
    t.boolean "locked", default: false, null: false
  end

  add_index "ci_runners", ["locked"], name: "index_ci_runners_on_locked", using: :btree
  add_index "ci_runners", ["token"], name: "index_ci_runners_on_token", using: :btree

  create_table "ci_sessions", force: :cascade do |t|
    t.string "session_id", limit: 255, null: false
    t.text "data", limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "ci_taggings", force: :cascade do |t|
    t.integer "tag_id", limit: 4
    t.integer "taggable_id", limit: 4
    t.string "taggable_type", limit: 255
    t.integer "tagger_id", limit: 4
    t.string "tagger_type", limit: 255
    t.string "context", limit: 128
    t.datetime "created_at"
  end

  add_index "ci_taggings", ["taggable_id", "taggable_type", "context"], name: "index_ci_taggings_on_taggable_id_and_taggable_type_and_context", using: :btree

  create_table "ci_tags", force: :cascade do |t|
    t.string "name", limit: 255
    t.integer "taggings_count", limit: 4, default: 0
  end

  create_table "ci_trigger_requests", force: :cascade do |t|
    t.integer "trigger_id", limit: 4, null: false
    t.text "variables", limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "commit_id", limit: 4
  end

  create_table "ci_triggers", force: :cascade do |t|
    t.string "token", limit: 255
    t.integer "project_id", limit: 4
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "gl_project_id", limit: 4
  end

  add_index "ci_triggers", ["gl_project_id"], name: "index_ci_triggers_on_gl_project_id", using: :btree

  create_table "ci_variables", force: :cascade do |t|
    t.integer "project_id", limit: 4
    t.string "key", limit: 255
    t.text "value", limit: 65535
    t.text "encrypted_value", limit: 65535
    t.string "encrypted_value_salt", limit: 255
    t.string "encrypted_value_iv", limit: 255
    t.integer "gl_project_id", limit: 4
  end

  add_index "ci_variables", ["gl_project_id"], name: "index_ci_variables_on_gl_project_id", using: :btree

  create_table "deploy_keys_projects", force: :cascade do |t|
    t.integer "deploy_key_id", limit: 4, null: false
    t.integer "project_id", limit: 4, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "deploy_keys_projects", ["project_id"], name: "index_deploy_keys_projects_on_project_id", using: :btree

  create_table "deployments", force: :cascade do |t|
    t.integer "iid", limit: 4, null: false
    t.integer "project_id", limit: 4, null: false
    t.integer "environment_id", limit: 4, null: false
    t.string "ref", limit: 255, null: false
    t.boolean "tag", null: false
    t.string "sha", limit: 255, null: false
    t.integer "user_id", limit: 4
    t.integer "deployable_id", limit: 4
    t.string "deployable_type", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "on_stop", limit: 255
  end

  add_index "deployments", ["project_id", "environment_id", "iid"], name: "index_deployments_on_project_id_and_environment_id_and_iid", using: :btree
  add_index "deployments", ["project_id", "environment_id"], name: "index_deployments_on_project_id_and_environment_id", using: :btree
  add_index "deployments", ["project_id", "iid"], name: "index_deployments_on_project_id_and_iid", unique: true, using: :btree
  add_index "deployments", ["project_id"], name: "index_deployments_on_project_id", using: :btree

  create_table "emails", force: :cascade do |t|
    t.integer "user_id", limit: 4, null: false
    t.string "email", limit: 255, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "emails", ["email"], name: "index_emails_on_email", unique: true, using: :btree
  add_index "emails", ["user_id"], name: "index_emails_on_user_id", using: :btree

  create_table "environments", force: :cascade do |t|
    t.integer "project_id", limit: 4
    t.string "name", limit: 255, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "external_url", limit: 255
    t.string "environment_type", limit: 255
    t.string "state", limit: 255, default: "available", null: false
  end

  add_index "environments", ["project_id", "name"], name: "index_environments_on_project_id_and_name", using: :btree

  create_table "events", force: :cascade do |t|
    t.string "target_type", limit: 255
    t.integer "target_id", limit: 4
    t.string "title", limit: 255
    t.text "data", limit: 4294967295
    t.integer "project_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "action", limit: 4
    t.integer "author_id", limit: 4
  end

  add_index "events", ["action"], name: "index_events_on_action", using: :btree
  add_index "events", ["author_id"], name: "index_events_on_author_id", using: :btree
  add_index "events", ["created_at"], name: "index_events_on_created_at", using: :btree
  add_index "events", ["project_id"], name: "index_events_on_project_id", using: :btree
  add_index "events", ["target_id"], name: "index_events_on_target_id", using: :btree
  add_index "events", ["target_type"], name: "index_events_on_target_type", using: :btree

  create_table "forked_project_links", force: :cascade do |t|
    t.integer "forked_to_project_id", limit: 4, null: false
    t.integer "forked_from_project_id", limit: 4, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "forked_project_links", ["forked_to_project_id"], name: "index_forked_project_links_on_forked_to_project_id", unique: true, using: :btree

  create_table "geo_nodes", force: :cascade do |t|
    t.string "schema", limit: 255
    t.string "host", limit: 255
    t.integer "port", limit: 4
    t.string "relative_url_root", limit: 255
    t.boolean "primary"
    t.integer "geo_node_key_id", limit: 4
    t.integer "oauth_application_id", limit: 4
    t.integer "system_hook_id", limit: 4
  end

  add_index "geo_nodes", ["host"], name: "index_geo_nodes_on_host", using: :btree
  add_index "geo_nodes", ["primary"], name: "index_geo_nodes_on_primary", using: :btree

  create_table "historical_data", force: :cascade do |t|
    t.date "date", null: false
    t.integer "active_user_count", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "identities", force: :cascade do |t|
    t.string "extern_uid", limit: 255
    t.string "provider", limit: 255
    t.integer "user_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "secondary_extern_uid", limit: 255
  end

  add_index "identities", ["user_id"], name: "index_identities_on_user_id", using: :btree

  create_table "index_statuses", force: :cascade do |t|
    t.integer "project_id", limit: 4, null: false
    t.datetime "indexed_at"
    t.text "note", limit: 65535
    t.string "last_commit", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "index_statuses", ["project_id"], name: "index_index_statuses_on_project_id", unique: true, using: :btree

  create_table "issue_metrics", force: :cascade do |t|
    t.integer "issue_id", limit: 4, null: false
    t.datetime "first_mentioned_in_commit_at"
    t.datetime "first_associated_with_milestone_at"
    t.datetime "first_added_to_board_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "issue_metrics", ["issue_id"], name: "index_issue_metrics", using: :btree

  create_table "issues", force: :cascade do |t|
    t.string "title", limit: 255
    t.integer "assignee_id", limit: 4
    t.integer "author_id", limit: 4
    t.integer "project_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "position", limit: 4, default: 0
    t.string "branch_name", limit: 255
    t.text "description", limit: 65535
    t.integer "milestone_id", limit: 4
    t.string "state", limit: 255
    t.integer "iid", limit: 4
    t.integer "updated_by_id", limit: 4
    t.integer "weight", limit: 4
    t.boolean "confidential", default: false
    t.datetime "deleted_at"
    t.date "due_date"
    t.integer "moved_to_id", limit: 4
    t.integer "lock_version", limit: 4
    t.text "title_html", limit: 65535
    t.text "description_html", limit: 65535
  end

  add_index "issues", ["assignee_id"], name: "index_issues_on_assignee_id", using: :btree
  add_index "issues", ["author_id"], name: "index_issues_on_author_id", using: :btree
  add_index "issues", ["confidential"], name: "index_issues_on_confidential", using: :btree
  add_index "issues", ["created_at"], name: "index_issues_on_created_at", using: :btree
  add_index "issues", ["deleted_at"], name: "index_issues_on_deleted_at", using: :btree
  add_index "issues", ["due_date"], name: "index_issues_on_due_date", using: :btree
  add_index "issues", ["milestone_id"], name: "index_issues_on_milestone_id", using: :btree
  add_index "issues", ["project_id", "iid"], name: "index_issues_on_project_id_and_iid", unique: true, using: :btree
  add_index "issues", ["state"], name: "index_issues_on_state", using: :btree

  create_table "keys", force: :cascade do |t|
    t.integer "user_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "key", limit: 65535
    t.string "title", limit: 255
    t.string "type", limit: 255
    t.string "fingerprint", limit: 255
    t.boolean "public", default: false, null: false
  end

  add_index "keys", ["fingerprint"], name: "index_keys_on_fingerprint", unique: true, using: :btree
  add_index "keys", ["user_id"], name: "index_keys_on_user_id", using: :btree

  create_table "label_links", force: :cascade do |t|
    t.integer "label_id", limit: 4
    t.integer "target_id", limit: 4
    t.string "target_type", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "label_links", ["label_id"], name: "index_label_links_on_label_id", using: :btree
  add_index "label_links", ["target_id", "target_type"], name: "index_label_links_on_target_id_and_target_type", using: :btree

  create_table "label_priorities", force: :cascade do |t|
    t.integer "project_id", limit: 4, null: false
    t.integer "label_id", limit: 4, null: false
    t.integer "priority", limit: 4, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "label_priorities", ["label_id"], name: "fk_rails_e161058b0f", using: :btree
  add_index "label_priorities", ["priority"], name: "index_label_priorities_on_priority", using: :btree
  add_index "label_priorities", ["project_id", "label_id"], name: "index_label_priorities_on_project_id_and_label_id", unique: true, using: :btree

  create_table "labels", force: :cascade do |t|
    t.string "title", limit: 255
    t.string "color", limit: 255
    t.integer "project_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "template", default: false
    t.string "description", limit: 255
    t.text "description_html", limit: 65535
    t.string "type", limit: 255
    t.integer "group_id", limit: 4
  end

  add_index "labels", ["group_id", "project_id", "title"], name: "index_labels_on_group_id_and_project_id_and_title", unique: true, using: :btree
  add_index "labels", ["group_id"], name: "index_labels_on_group_id", using: :btree

  create_table "ldap_group_links", force: :cascade do |t|
    t.string "cn", limit: 255, null: false
    t.integer "group_access", limit: 4, null: false
    t.integer "group_id", limit: 4, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "provider", limit: 255
  end

  create_table "lfs_objects", force: :cascade do |t|
    t.string "oid", limit: 255, null: false
    t.integer "size", limit: 8, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "file", limit: 255
  end

  add_index "lfs_objects", ["oid"], name: "index_lfs_objects_on_oid", unique: true, using: :btree

  create_table "lfs_objects_projects", force: :cascade do |t|
    t.integer "lfs_object_id", limit: 4, null: false
    t.integer "project_id", limit: 4, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "lfs_objects_projects", ["project_id"], name: "index_lfs_objects_projects_on_project_id", using: :btree

  create_table "licenses", force: :cascade do |t|
    t.text "data", limit: 65535, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "lists", force: :cascade do |t|
    t.integer "board_id", limit: 4, null: false
    t.integer "label_id", limit: 4
    t.integer "list_type", limit: 4, default: 1, null: false
    t.integer "position", limit: 4
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "lists", ["board_id", "label_id"], name: "index_lists_on_board_id_and_label_id", unique: true, using: :btree
  add_index "lists", ["board_id"], name: "index_lists_on_board_id", using: :btree
  add_index "lists", ["label_id"], name: "index_lists_on_label_id", using: :btree

  create_table "members", force: :cascade do |t|
    t.integer "access_level", limit: 4, null: false
    t.integer "source_id", limit: 4, null: false
    t.string "source_type", limit: 255, null: false
    t.integer "user_id", limit: 4
    t.integer "notification_level", limit: 4, null: false
    t.string "type", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "created_by_id", limit: 4
    t.string "invite_email", limit: 255
    t.string "invite_token", limit: 255
    t.datetime "invite_accepted_at"
    t.datetime "requested_at"
    t.date "expires_at"
    t.boolean "ldap", default: false, null: false
    t.boolean "override", default: false, null: false
  end

  add_index "members", ["access_level"], name: "index_members_on_access_level", using: :btree
  add_index "members", ["invite_token"], name: "index_members_on_invite_token", unique: true, using: :btree
  add_index "members", ["requested_at"], name: "index_members_on_requested_at", using: :btree
  add_index "members", ["source_id", "source_type"], name: "index_members_on_source_id_and_source_type", using: :btree
  add_index "members", ["user_id"], name: "index_members_on_user_id", using: :btree

  create_table "merge_request_diffs", force: :cascade do |t|
    t.string "state", limit: 255
    t.text "st_commits", limit: 4294967295
    t.text "st_diffs", limit: 4294967295
    t.integer "merge_request_id", limit: 4, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "base_commit_sha", limit: 255
    t.string "real_size", limit: 255
    t.string "head_commit_sha", limit: 255
    t.string "start_commit_sha", limit: 255
  end

  add_index "merge_request_diffs", ["merge_request_id"], name: "index_merge_request_diffs_on_merge_request_id", using: :btree

  create_table "merge_request_metrics", force: :cascade do |t|
    t.integer "merge_request_id", limit: 4, null: false
    t.datetime "latest_build_started_at"
    t.datetime "latest_build_finished_at"
    t.datetime "first_deployed_to_production_at"
    t.datetime "merged_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "pipeline_id", limit: 4
  end

  add_index "merge_request_metrics", ["first_deployed_to_production_at"], name: "index_merge_request_metrics_on_first_deployed_to_production_at", using: :btree
  add_index "merge_request_metrics", ["merge_request_id"], name: "index_merge_request_metrics", using: :btree
  add_index "merge_request_metrics", ["pipeline_id"], name: "index_merge_request_metrics_on_pipeline_id", using: :btree

  create_table "merge_requests", force: :cascade do |t|
    t.string "target_branch", limit: 255, null: false
    t.string "source_branch", limit: 255, null: false
    t.integer "source_project_id", limit: 4, null: false
    t.integer "author_id", limit: 4
    t.integer "assignee_id", limit: 4
    t.string "title", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "milestone_id", limit: 4
    t.string "state", limit: 255
    t.string "merge_status", limit: 255
    t.integer "target_project_id", limit: 4, null: false
    t.integer "iid", limit: 4
    t.text "description", limit: 65535
    t.integer "position", limit: 4, default: 0
    t.datetime "locked_at"
    t.integer "updated_by_id", limit: 4
    t.text "merge_error", limit: 65535
    t.text "merge_params", limit: 65535
    t.boolean "merge_when_build_succeeds", default: false, null: false
    t.integer "merge_user_id", limit: 4
    t.string "merge_commit_sha", limit: 255
    t.datetime "deleted_at"
    t.integer "approvals_before_merge", limit: 4
    t.string "rebase_commit_sha", limit: 255
    t.string "in_progress_merge_commit_sha", limit: 255
    t.integer "lock_version", limit: 4
    t.text "title_html", limit: 65535
    t.text "description_html", limit: 65535
  end

  add_index "merge_requests", ["assignee_id"], name: "index_merge_requests_on_assignee_id", using: :btree
  add_index "merge_requests", ["author_id"], name: "index_merge_requests_on_author_id", using: :btree
  add_index "merge_requests", ["created_at"], name: "index_merge_requests_on_created_at", using: :btree
  add_index "merge_requests", ["deleted_at"], name: "index_merge_requests_on_deleted_at", using: :btree
  add_index "merge_requests", ["milestone_id"], name: "index_merge_requests_on_milestone_id", using: :btree
  add_index "merge_requests", ["source_branch"], name: "index_merge_requests_on_source_branch", using: :btree
  add_index "merge_requests", ["source_project_id"], name: "index_merge_requests_on_source_project_id", using: :btree
  add_index "merge_requests", ["target_branch"], name: "index_merge_requests_on_target_branch", using: :btree
  add_index "merge_requests", ["target_project_id", "iid"], name: "index_merge_requests_on_target_project_id_and_iid", unique: true, using: :btree
  add_index "merge_requests", ["title"], name: "index_merge_requests_on_title", using: :btree

  create_table "merge_requests_closing_issues", force: :cascade do |t|
    t.integer "merge_request_id", limit: 4, null: false
    t.integer "issue_id", limit: 4, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "merge_requests_closing_issues", ["issue_id"], name: "index_merge_requests_closing_issues_on_issue_id", using: :btree
  add_index "merge_requests_closing_issues", ["merge_request_id"], name: "index_merge_requests_closing_issues_on_merge_request_id", using: :btree

  create_table "milestones", force: :cascade do |t|
    t.string "title", limit: 255, null: false
    t.integer "project_id", limit: 4, null: false
    t.text "description", limit: 65535
    t.date "due_date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "state", limit: 255
    t.integer "iid", limit: 4
    t.text "title_html", limit: 65535
    t.text "description_html", limit: 65535
  end

  add_index "milestones", ["due_date"], name: "index_milestones_on_due_date", using: :btree
  add_index "milestones", ["project_id", "iid"], name: "index_milestones_on_project_id_and_iid", unique: true, using: :btree
  add_index "milestones", ["project_id"], name: "index_milestones_on_project_id", using: :btree
  add_index "milestones", ["title"], name: "index_milestones_on_title", using: :btree

  create_table "namespaces", force: :cascade do |t|
    t.string "name", limit: 255, null: false
    t.string "path", limit: 255, null: false
    t.integer "owner_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "type", limit: 255
    t.string "description", limit: 255, default: "", null: false
    t.string "avatar", limit: 255
    t.boolean "membership_lock", default: false
    t.boolean "share_with_group_lock", default: false
    t.integer "visibility_level", limit: 4, default: 20, null: false
    t.boolean "request_access_enabled", default: false, null: false
    t.datetime "deleted_at"
    t.string "ldap_sync_status", limit: 255, default: "ready", null: false
    t.string "ldap_sync_error", limit: 255
    t.datetime "ldap_sync_last_update_at"
    t.datetime "ldap_sync_last_successful_update_at"
    t.datetime "ldap_sync_last_sync_at"
    t.boolean "lfs_enabled"
    t.integer "repository_size_limit", limit: 4
    t.text "description_html", limit: 65535
  end

  add_index "namespaces", ["created_at"], name: "index_namespaces_on_created_at", using: :btree
  add_index "namespaces", ["deleted_at"], name: "index_namespaces_on_deleted_at", using: :btree
  add_index "namespaces", ["ldap_sync_last_successful_update_at"], name: "index_namespaces_on_ldap_sync_last_successful_update_at", using: :btree
  add_index "namespaces", ["ldap_sync_last_update_at"], name: "index_namespaces_on_ldap_sync_last_update_at", using: :btree
  add_index "namespaces", ["name"], name: "index_namespaces_on_name", unique: true, using: :btree
  add_index "namespaces", ["owner_id"], name: "index_namespaces_on_owner_id", using: :btree
  add_index "namespaces", ["path"], name: "index_namespaces_on_path", unique: true, using: :btree
  add_index "namespaces", ["type"], name: "index_namespaces_on_type", using: :btree

  create_table "notes", force: :cascade do |t|
    t.text "note", limit: 65535
    t.string "noteable_type", limit: 255
    t.integer "author_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "project_id", limit: 4
    t.string "attachment", limit: 255
    t.string "line_code", limit: 255
    t.string "commit_id", limit: 255
    t.integer "noteable_id", limit: 4
    t.boolean "system", default: false, null: false
    t.text "st_diff", limit: 4294967295
    t.integer "updated_by_id", limit: 4
    t.string "type", limit: 255
    t.text "position", limit: 65535
    t.text "original_position", limit: 65535
    t.datetime "resolved_at"
    t.integer "resolved_by_id", limit: 4
    t.string "discussion_id", limit: 255
    t.string "original_discussion_id", limit: 255
    t.text "note_html", limit: 65535
  end

  add_index "notes", ["author_id"], name: "index_notes_on_author_id", using: :btree
  add_index "notes", ["commit_id"], name: "index_notes_on_commit_id", using: :btree
  add_index "notes", ["created_at"], name: "index_notes_on_created_at", using: :btree
  add_index "notes", ["discussion_id"], name: "index_notes_on_discussion_id", using: :btree
  add_index "notes", ["line_code"], name: "index_notes_on_line_code", using: :btree
  add_index "notes", ["noteable_id", "noteable_type"], name: "index_notes_on_noteable_id_and_noteable_type", using: :btree
  add_index "notes", ["noteable_type"], name: "index_notes_on_noteable_type", using: :btree
  add_index "notes", ["project_id", "noteable_type"], name: "index_notes_on_project_id_and_noteable_type", using: :btree
  add_index "notes", ["project_id"], name: "index_notes_on_project_id", using: :btree
  add_index "notes", ["updated_at"], name: "index_notes_on_updated_at", using: :btree

  create_table "notification_settings", force: :cascade do |t|
    t.integer "user_id", limit: 4, null: false
    t.integer "source_id", limit: 4
    t.string "source_type", limit: 255
    t.integer "level", limit: 4, default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "events", limit: 65535
  end

  add_index "notification_settings", ["source_id", "source_type"], name: "index_notification_settings_on_source_id_and_source_type", using: :btree
  add_index "notification_settings", ["user_id", "source_id", "source_type"], name: "index_notifications_on_user_id_and_source_id_and_source_type", unique: true, using: :btree
  add_index "notification_settings", ["user_id"], name: "index_notification_settings_on_user_id", using: :btree

  create_table "oauth_access_grants", force: :cascade do |t|
    t.integer "resource_owner_id", limit: 4, null: false
    t.integer "application_id", limit: 4, null: false
    t.string "token", limit: 255, null: false
    t.integer "expires_in", limit: 4, null: false
    t.text "redirect_uri", limit: 65535, null: false
    t.datetime "created_at", null: false
    t.datetime "revoked_at"
    t.string "scopes", limit: 255
  end

  add_index "oauth_access_grants", ["token"], name: "index_oauth_access_grants_on_token", unique: true, using: :btree

  create_table "oauth_access_tokens", force: :cascade do |t|
    t.integer "resource_owner_id", limit: 4
    t.integer "application_id", limit: 4
    t.string "token", limit: 255, null: false
    t.string "refresh_token", limit: 255
    t.integer "expires_in", limit: 4
    t.datetime "revoked_at"
    t.datetime "created_at", null: false
    t.string "scopes", limit: 255
  end

  add_index "oauth_access_tokens", ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true, using: :btree
  add_index "oauth_access_tokens", ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id", using: :btree
  add_index "oauth_access_tokens", ["token"], name: "index_oauth_access_tokens_on_token", unique: true, using: :btree

  create_table "oauth_applications", force: :cascade do |t|
    t.string "name", limit: 255, null: false
    t.string "uid", limit: 255, null: false
    t.string "secret", limit: 255, null: false
    t.text "redirect_uri", limit: 65535, null: false
    t.string "scopes", limit: 255, default: "", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "owner_id", limit: 4
    t.string "owner_type", limit: 255
  end

  add_index "oauth_applications", ["owner_id", "owner_type"], name: "index_oauth_applications_on_owner_id_and_owner_type", using: :btree
  add_index "oauth_applications", ["uid"], name: "index_oauth_applications_on_uid", unique: true, using: :btree

  create_table "pages_domains", force: :cascade do |t|
    t.integer "project_id", limit: 4
    t.text "certificate", limit: 65535
    t.text "encrypted_key", limit: 65535
    t.string "encrypted_key_iv", limit: 255
    t.string "encrypted_key_salt", limit: 255
    t.string "domain", limit: 255
  end

  add_index "pages_domains", ["domain"], name: "index_pages_domains_on_domain", unique: true, using: :btree

  create_table "path_locks", force: :cascade do |t|
    t.string "path", limit: 255, null: false
    t.integer "project_id", limit: 4
    t.integer "user_id", limit: 4
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "path_locks", ["path"], name: "index_path_locks_on_path", using: :btree
  add_index "path_locks", ["project_id"], name: "index_path_locks_on_project_id", using: :btree
  add_index "path_locks", ["user_id"], name: "index_path_locks_on_user_id", using: :btree

  create_table "personal_access_tokens", force: :cascade do |t|
    t.integer "user_id", limit: 4, null: false
    t.string "token", limit: 255, null: false
    t.string "name", limit: 255, null: false
    t.boolean "revoked", default: false
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "personal_access_tokens", ["token"], name: "index_personal_access_tokens_on_token", unique: true, using: :btree
  add_index "personal_access_tokens", ["user_id"], name: "index_personal_access_tokens_on_user_id", using: :btree

  create_table "project_features", force: :cascade do |t|
    t.integer "project_id", limit: 4
    t.integer "merge_requests_access_level", limit: 4
    t.integer "issues_access_level", limit: 4
    t.integer "wiki_access_level", limit: 4
    t.integer "snippets_access_level", limit: 4
    t.integer "builds_access_level", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "repository_access_level", limit: 4, default: 20, null: false
  end

  add_index "project_features", ["project_id"], name: "index_project_features_on_project_id", using: :btree

  create_table "project_group_links", force: :cascade do |t|
    t.integer "project_id", limit: 4, null: false
    t.integer "group_id", limit: 4, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "group_access", limit: 4, default: 30, null: false
    t.date "expires_at"
  end

  create_table "project_import_data", force: :cascade do |t|
    t.integer "project_id", limit: 4
    t.text "data", limit: 65535
    t.text "encrypted_credentials", limit: 65535
    t.string "encrypted_credentials_iv", limit: 255
    t.string "encrypted_credentials_salt", limit: 255
  end

  add_index "project_import_data", ["project_id"], name: "index_project_import_data_on_project_id", using: :btree

  create_table "projects", force: :cascade do |t|
    t.string "name", limit: 255
    t.string "path", limit: 255
    t.text "description", limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "creator_id", limit: 4
    t.integer "namespace_id", limit: 4
    t.datetime "last_activity_at"
    t.string "import_url", limit: 255
    t.integer "visibility_level", limit: 4, default: 0, null: false
    t.boolean "archived", default: false, null: false
    t.string "avatar", limit: 255
    t.string "import_status", limit: 255
    t.float "repository_size", limit: 24, default: 0.0
    t.text "merge_requests_template", limit: 65535
    t.integer "star_count", limit: 4, default: 0, null: false
    t.boolean "merge_requests_rebase_enabled", default: false
    t.string "import_type", limit: 255
    t.string "import_source", limit: 255
    t.integer "approvals_before_merge", limit: 4, default: 0, null: false
    t.boolean "reset_approvals_on_push", default: true
    t.integer "commit_count", limit: 4, default: 0
    t.boolean "merge_requests_ff_only_enabled", default: false
    t.text "issues_template", limit: 65535
    t.boolean "mirror", default: false, null: false
    t.datetime "mirror_last_update_at"
    t.datetime "mirror_last_successful_update_at"
    t.integer "mirror_user_id", limit: 4
    t.text "import_error", limit: 65535
    t.integer "ci_id", limit: 4
    t.boolean "shared_runners_enabled", default: true, null: false
    t.string "runners_token", limit: 255
    t.string "build_coverage_regex", limit: 255
    t.boolean "build_allow_git_fetch", default: true, null: false
    t.integer "build_timeout", limit: 4, default: 3600, null: false
    t.boolean "mirror_trigger_builds", default: false, null: false
    t.boolean "pending_delete", default: false
    t.boolean "public_builds", default: true, null: false
    t.boolean "last_repository_check_failed"
    t.datetime "last_repository_check_at"
    t.boolean "container_registry_enabled"
    t.boolean "only_allow_merge_if_build_succeeds", default: false, null: false
    t.boolean "has_external_issue_tracker"
    t.string "repository_storage", limit: 255, default: "default", null: false
    t.boolean "request_access_enabled", default: false, null: false
    t.boolean "has_external_wiki"
    t.boolean "repository_read_only"
    t.boolean "lfs_enabled"
    t.integer "repository_size_limit", limit: 4
    t.text "description_html", limit: 65535
    t.boolean "only_allow_merge_if_all_discussions_are_resolved", default: false, null: false
  end

  add_index "projects", ["ci_id"], name: "index_projects_on_ci_id", using: :btree
  add_index "projects", ["created_at"], name: "index_projects_on_created_at", using: :btree
  add_index "projects", ["creator_id"], name: "index_projects_on_creator_id", using: :btree
  add_index "projects", ["last_activity_at"], name: "index_projects_on_last_activity_at", using: :btree
  add_index "projects", ["last_repository_check_failed"], name: "index_projects_on_last_repository_check_failed", using: :btree
  add_index "projects", ["namespace_id"], name: "index_projects_on_namespace_id", using: :btree
  add_index "projects", ["path"], name: "index_projects_on_path", using: :btree
  add_index "projects", ["pending_delete"], name: "index_projects_on_pending_delete", using: :btree
  add_index "projects", ["runners_token"], name: "index_projects_on_runners_token", using: :btree
  add_index "projects", ["star_count"], name: "index_projects_on_star_count", using: :btree
  add_index "projects", ["visibility_level"], name: "index_projects_on_visibility_level", using: :btree

  create_table "protected_branch_merge_access_levels", force: :cascade do |t|
    t.integer "protected_branch_id", limit: 4, null: false
    t.integer "access_level", limit: 4, default: 40
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", limit: 4
    t.integer "group_id", limit: 4
  end

  add_index "protected_branch_merge_access_levels", ["group_id"], name: "fk_rails_98f3d044fe", using: :btree
  add_index "protected_branch_merge_access_levels", ["protected_branch_id"], name: "index_protected_branch_merge_access", using: :btree
  add_index "protected_branch_merge_access_levels", ["user_id"], name: "index_protected_branch_merge_access_levels_on_user_id", using: :btree

  create_table "protected_branch_push_access_levels", force: :cascade do |t|
    t.integer "protected_branch_id", limit: 4, null: false
    t.integer "access_level", limit: 4, default: 40
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", limit: 4
    t.integer "group_id", limit: 4
  end

  add_index "protected_branch_push_access_levels", ["group_id"], name: "fk_rails_7111b68cdb", using: :btree
  add_index "protected_branch_push_access_levels", ["protected_branch_id"], name: "index_protected_branch_push_access", using: :btree
  add_index "protected_branch_push_access_levels", ["user_id"], name: "index_protected_branch_push_access_levels_on_user_id", using: :btree

  create_table "protected_branches", force: :cascade do |t|
    t.integer "project_id", limit: 4, null: false
    t.string "name", limit: 255, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "protected_branches", ["project_id"], name: "index_protected_branches_on_project_id", using: :btree

  create_table "push_rules", force: :cascade do |t|
    t.string "force_push_regex", limit: 255
    t.string "delete_branch_regex", limit: 255
    t.string "commit_message_regex", limit: 255
    t.boolean "deny_delete_tag"
    t.integer "project_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "author_email_regex", limit: 255
    t.boolean "member_check", default: false, null: false
    t.string "file_name_regex", limit: 255
    t.boolean "is_sample", default: false
    t.integer "max_file_size", limit: 4, default: 0, null: false
    t.boolean "prevent_secrets", default: false, null: false
  end

  add_index "push_rules", ["project_id"], name: "index_push_rules_on_project_id", using: :btree

  create_table "releases", force: :cascade do |t|
    t.string "tag", limit: 255
    t.text "description", limit: 65535
    t.integer "project_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "description_html", limit: 65535
  end

  add_index "releases", ["project_id", "tag"], name: "index_releases_on_project_id_and_tag", using: :btree
  add_index "releases", ["project_id"], name: "index_releases_on_project_id", using: :btree

  create_table "remote_mirrors", force: :cascade do |t|
    t.integer "project_id", limit: 4
    t.string "url", limit: 255
    t.boolean "enabled", default: false
    t.string "update_status", limit: 255
    t.datetime "last_update_at"
    t.datetime "last_successful_update_at"
    t.string "last_error", limit: 255
    t.text "encrypted_credentials", limit: 65535
    t.string "encrypted_credentials_iv", limit: 255
    t.string "encrypted_credentials_salt", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "remote_mirrors", ["project_id"], name: "index_remote_mirrors_on_project_id", using: :btree

  create_table "sent_notifications", force: :cascade do |t|
    t.integer "project_id", limit: 4
    t.integer "noteable_id", limit: 4
    t.string "noteable_type", limit: 255
    t.integer "recipient_id", limit: 4
    t.string "commit_id", limit: 255
    t.string "reply_key", limit: 255, null: false
    t.string "line_code", limit: 255
    t.string "note_type", limit: 255
    t.text "position", limit: 65535
  end

  add_index "sent_notifications", ["reply_key"], name: "index_sent_notifications_on_reply_key", unique: true, using: :btree

  create_table "services", force: :cascade do |t|
    t.string "type", limit: 255
    t.string "title", limit: 255
    t.integer "project_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "active", default: false, null: false
    t.text "properties", limit: 65535
    t.boolean "template", default: false
    t.boolean "push_events", default: true
    t.boolean "issues_events", default: true
    t.boolean "merge_requests_events", default: true
    t.boolean "tag_push_events", default: true
    t.boolean "note_events", default: true, null: false
    t.boolean "build_events", default: false, null: false
    t.string "category", limit: 255, default: "common", null: false
    t.boolean "default", default: false
    t.boolean "wiki_page_events", default: true
    t.boolean "pipeline_events", default: false, null: false
    t.boolean "confidential_issues_events", default: true, null: false
  end

  add_index "services", ["project_id"], name: "index_services_on_project_id", using: :btree
  add_index "services", ["template"], name: "index_services_on_template", using: :btree

  create_table "snippets", force: :cascade do |t|
    t.string "title", limit: 255
    t.text "content", limit: 4294967295
    t.integer "author_id", limit: 4, null: false
    t.integer "project_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "file_name", limit: 255
    t.string "type", limit: 255
    t.integer "visibility_level", limit: 4, default: 0, null: false
    t.text "title_html", limit: 65535
    t.text "content_html", limit: 65535
  end

  add_index "snippets", ["author_id"], name: "index_snippets_on_author_id", using: :btree
  add_index "snippets", ["project_id"], name: "index_snippets_on_project_id", using: :btree
  add_index "snippets", ["updated_at"], name: "index_snippets_on_updated_at", using: :btree
  add_index "snippets", ["visibility_level"], name: "index_snippets_on_visibility_level", using: :btree

  create_table "spam_logs", force: :cascade do |t|
    t.integer "user_id", limit: 4
    t.string "source_ip", limit: 255
    t.string "user_agent", limit: 255
    t.boolean "via_api"
    t.string "noteable_type", limit: 255
    t.string "title", limit: 255
    t.text "description", limit: 65535
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "submitted_as_ham", default: false, null: false
  end

  create_table "subscriptions", force: :cascade do |t|
    t.integer "user_id", limit: 4
    t.integer "subscribable_id", limit: 4
    t.string "subscribable_type", limit: 255
    t.boolean "subscribed"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "subscriptions", ["subscribable_id", "subscribable_type", "user_id"], name: "subscriptions_user_id_and_ref_fields", unique: true, using: :btree

  create_table "taggings", force: :cascade do |t|
    t.integer "tag_id", limit: 4
    t.integer "taggable_id", limit: 4
    t.string "taggable_type", limit: 255
    t.integer "tagger_id", limit: 4
    t.string "tagger_type", limit: 255
    t.string "context", limit: 255
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "taggings_idx", unique: true, using: :btree
  add_index "taggings", ["taggable_id", "taggable_type", "context"], name: "index_taggings_on_taggable_id_and_taggable_type_and_context", using: :btree

  create_table "tags", force: :cascade do |t|
    t.string "name", limit: 255
    t.integer "taggings_count", limit: 4, default: 0
  end

  add_index "tags", ["name"], name: "index_tags_on_name", unique: true, using: :btree

  create_table "todos", force: :cascade do |t|
    t.integer "user_id", limit: 4, null: false
    t.integer "project_id", limit: 4, null: false
    t.integer "target_id", limit: 4
    t.string "target_type", limit: 255, null: false
    t.integer "author_id", limit: 4
    t.integer "action", limit: 4, null: false
    t.string "state", limit: 255, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "note_id", limit: 4
    t.string "commit_id", limit: 255
  end

  add_index "todos", ["author_id"], name: "index_todos_on_author_id", using: :btree
  add_index "todos", ["commit_id"], name: "index_todos_on_commit_id", using: :btree
  add_index "todos", ["note_id"], name: "index_todos_on_note_id", using: :btree
  add_index "todos", ["project_id"], name: "index_todos_on_project_id", using: :btree
  add_index "todos", ["target_type", "target_id"], name: "index_todos_on_target_type_and_target_id", using: :btree
  add_index "todos", ["user_id"], name: "index_todos_on_user_id", using: :btree

  create_table "trending_projects", force: :cascade do |t|
    t.integer "project_id", limit: 4, null: false
  end

  add_index "trending_projects", ["project_id"], name: "index_trending_projects_on_project_id", using: :btree

  create_table "u2f_registrations", force: :cascade do |t|
    t.text "certificate", limit: 65535
    t.string "key_handle", limit: 255
    t.string "public_key", limit: 255
    t.integer "counter", limit: 4
    t.integer "user_id", limit: 4
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name", limit: 255
  end

  add_index "u2f_registrations", ["key_handle"], name: "index_u2f_registrations_on_key_handle", using: :btree
  add_index "u2f_registrations", ["user_id"], name: "index_u2f_registrations_on_user_id", using: :btree

  create_table "user_activities", force: :cascade do |t|
    t.integer "user_id", limit: 4
    t.datetime "last_activity_at", null: false
  end

  add_index "user_activities", ["user_id"], name: "index_user_activities_on_user_id", unique: true, using: :btree

  create_table "user_agent_details", force: :cascade do |t|
    t.string "user_agent", limit: 255, null: false
    t.string "ip_address", limit: 255, null: false
    t.integer "subject_id", limit: 4, null: false
    t.string "subject_type", limit: 255, null: false
    t.boolean "submitted", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email", limit: 255, default: "", null: false
    t.string "encrypted_password", limit: 255, default: "", null: false
    t.string "reset_password_token", limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", limit: 4, default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip", limit: 255
    t.string "last_sign_in_ip", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "name", limit: 255
    t.boolean "admin", default: false, null: false
    t.integer "projects_limit", limit: 4, default: 10
    t.string "skype", limit: 255, default: "", null: false
    t.string "linkedin", limit: 255, default: "", null: false
    t.string "twitter", limit: 255, default: "", null: false
    t.string "authentication_token", limit: 255
    t.integer "theme_id", limit: 4, default: 1, null: false
    t.string "bio", limit: 255
    t.integer "failed_attempts", limit: 4, default: 0
    t.datetime "locked_at"
    t.string "username", limit: 255
    t.boolean "can_create_group", default: true, null: false
    t.boolean "can_create_team", default: true, null: false
    t.string "state", limit: 255
    t.integer "color_scheme_id", limit: 4, default: 1, null: false
    t.datetime "password_expires_at"
    t.integer "created_by_id", limit: 4
    t.datetime "last_credential_check_at"
    t.string "avatar", limit: 255
    t.string "confirmation_token", limit: 255
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email", limit: 255
    t.boolean "hide_no_ssh_key", default: false
    t.string "website_url", limit: 255, default: "", null: false
    t.datetime "admin_email_unsubscribed_at"
    t.string "notification_email", limit: 255
    t.boolean "hide_no_password", default: false
    t.boolean "password_automatically_set", default: false
    t.string "location", limit: 255
    t.string "encrypted_otp_secret", limit: 255
    t.string "encrypted_otp_secret_iv", limit: 255
    t.string "encrypted_otp_secret_salt", limit: 255
    t.boolean "otp_required_for_login", default: false, null: false
    t.text "otp_backup_codes", limit: 65535
    t.string "public_email", limit: 255, default: "", null: false
    t.integer "dashboard", limit: 4, default: 0
    t.integer "project_view", limit: 4, default: 0
    t.integer "consumed_timestep", limit: 4
    t.integer "layout", limit: 4, default: 0
    t.boolean "hide_project_limit", default: false
    t.text "note", limit: 65535
    t.string "unlock_token", limit: 255
    t.datetime "otp_grace_period_started_at"
    t.boolean "ldap_email", default: false, null: false
    t.boolean "external", default: false
    t.string "organization", limit: 255
    t.string "incoming_email_token", limit: 255
  end

  add_index "users", ["admin"], name: "index_users_on_admin", using: :btree
  add_index "users", ["authentication_token"], name: "index_users_on_authentication_token", unique: true, using: :btree
  add_index "users", ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true, using: :btree
  add_index "users", ["created_at"], name: "index_users_on_created_at", using: :btree
  add_index "users", ["current_sign_in_at"], name: "index_users_on_current_sign_in_at", using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["incoming_email_token"], name: "index_users_on_incoming_email_token", using: :btree
  add_index "users", ["name"], name: "index_users_on_name", using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["state"], name: "index_users_on_state", using: :btree
  add_index "users", ["username"], name: "index_users_on_username", using: :btree

  create_table "users_star_projects", force: :cascade do |t|
    t.integer "project_id", limit: 4, null: false
    t.integer "user_id", limit: 4, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users_star_projects", ["project_id"], name: "index_users_star_projects_on_project_id", using: :btree
  add_index "users_star_projects", ["user_id", "project_id"], name: "index_users_star_projects_on_user_id_and_project_id", unique: true, using: :btree
  add_index "users_star_projects", ["user_id"], name: "index_users_star_projects_on_user_id", using: :btree

  create_table "web_hooks", force: :cascade do |t|
    t.string "url", limit: 2000
    t.integer "project_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "type", limit: 255, default: "ProjectHook"
    t.integer "service_id", limit: 4
    t.boolean "push_events", default: true, null: false
    t.boolean "issues_events", default: false, null: false
    t.boolean "merge_requests_events", default: false, null: false
    t.boolean "tag_push_events", default: false
    t.integer "group_id", limit: 4
    t.boolean "note_events", default: false, null: false
    t.boolean "enable_ssl_verification", default: true
    t.boolean "build_events", default: false, null: false
    t.string "token", limit: 255
    t.boolean "wiki_page_events", default: false, null: false
    t.boolean "pipeline_events", default: false, null: false
    t.boolean "confidential_issues_events", default: false, null: false
  end

  add_index "web_hooks", ["project_id"], name: "index_web_hooks_on_project_id", using: :btree

  add_foreign_key "approver_groups", "namespaces", column: "group_id", on_delete: :cascade
  add_foreign_key "boards", "projects"
  add_foreign_key "issue_metrics", "issues", on_delete: :cascade
  add_foreign_key "label_priorities", "labels", on_delete: :cascade
  add_foreign_key "label_priorities", "projects", on_delete: :cascade
  add_foreign_key "labels", "namespaces", column: "group_id", on_delete: :cascade
  add_foreign_key "lists", "boards"
  add_foreign_key "lists", "labels"
  add_foreign_key "merge_request_metrics", "ci_commits", column: "pipeline_id", on_delete: :cascade
  add_foreign_key "merge_request_metrics", "merge_requests", on_delete: :cascade
  add_foreign_key "merge_requests_closing_issues", "issues", on_delete: :cascade
  add_foreign_key "merge_requests_closing_issues", "merge_requests", on_delete: :cascade
  add_foreign_key "path_locks", "projects"
  add_foreign_key "path_locks", "users"
  add_foreign_key "personal_access_tokens", "users"
  add_foreign_key "protected_branch_merge_access_levels", "namespaces", column: "group_id"
  add_foreign_key "protected_branch_merge_access_levels", "protected_branches"
  add_foreign_key "protected_branch_merge_access_levels", "users"
  add_foreign_key "protected_branch_push_access_levels", "namespaces", column: "group_id"
  add_foreign_key "protected_branch_push_access_levels", "protected_branches"
  add_foreign_key "protected_branch_push_access_levels", "users"
  add_foreign_key "remote_mirrors", "projects"
  add_foreign_key "trending_projects", "projects", on_delete: :cascade
  add_foreign_key "u2f_registrations", "users"
  add_foreign_key "user_activities", "users", on_delete: :cascade
end
