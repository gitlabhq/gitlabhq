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

ActiveRecord::Schema.define(version: 20190530154715) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "pg_trgm"

  create_table "abuse_reports", id: :serial, force: :cascade do |t|
    t.integer "reporter_id"
    t.integer "user_id"
    t.text "message"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "message_html"
    t.integer "cached_markdown_version"
  end

  create_table "appearances", id: :serial, force: :cascade do |t|
    t.string "title", null: false
    t.text "description", null: false
    t.string "header_logo"
    t.string "logo"
    t.datetime_with_timezone "created_at", null: false
    t.datetime_with_timezone "updated_at", null: false
    t.text "description_html"
    t.integer "cached_markdown_version"
    t.text "new_project_guidelines"
    t.text "new_project_guidelines_html"
    t.text "header_message"
    t.text "header_message_html"
    t.text "footer_message"
    t.text "footer_message_html"
    t.text "message_background_color"
    t.text "message_font_color"
    t.string "favicon"
    t.boolean "email_header_and_footer_enabled", default: false, null: false
  end

  create_table "application_setting_terms", id: :serial, force: :cascade do |t|
    t.integer "cached_markdown_version"
    t.text "terms", null: false
    t.text "terms_html"
  end

  create_table "application_settings", id: :serial, force: :cascade do |t|
    t.integer "default_projects_limit"
    t.boolean "signup_enabled"
    t.boolean "gravatar_enabled"
    t.text "sign_in_text"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "home_page_url"
    t.integer "default_branch_protection", default: 2
    t.text "restricted_visibility_levels"
    t.boolean "version_check_enabled", default: true
    t.integer "max_attachment_size", default: 10, null: false
    t.integer "default_project_visibility"
    t.integer "default_snippet_visibility"
    t.text "domain_whitelist"
    t.boolean "user_oauth_applications", default: true
    t.string "after_sign_out_path"
    t.integer "session_expire_delay", default: 10080, null: false
    t.text "import_sources"
    t.text "help_page_text"
    t.string "admin_notification_email"
    t.boolean "shared_runners_enabled", default: true, null: false
    t.integer "max_artifacts_size", default: 100, null: false
    t.string "runners_registration_token"
    t.integer "max_pages_size", default: 100, null: false
    t.boolean "require_two_factor_authentication", default: false
    t.integer "two_factor_grace_period", default: 48
    t.boolean "metrics_enabled", default: false
    t.string "metrics_host", default: "localhost"
    t.integer "metrics_pool_size", default: 16
    t.integer "metrics_timeout", default: 10
    t.integer "metrics_method_call_threshold", default: 10
    t.boolean "recaptcha_enabled", default: false
    t.string "recaptcha_site_key"
    t.string "recaptcha_private_key"
    t.integer "metrics_port", default: 8089
    t.boolean "akismet_enabled", default: false
    t.string "akismet_api_key"
    t.integer "metrics_sample_interval", default: 15
    t.boolean "sentry_enabled", default: false
    t.string "sentry_dsn"
    t.boolean "email_author_in_body", default: false
    t.integer "default_group_visibility"
    t.boolean "repository_checks_enabled", default: false
    t.text "shared_runners_text"
    t.integer "metrics_packet_size", default: 1
    t.text "disabled_oauth_sign_in_sources"
    t.string "health_check_access_token"
    t.boolean "send_user_confirmation_email", default: false
    t.integer "container_registry_token_expire_delay", default: 5
    t.text "after_sign_up_text"
    t.boolean "user_default_external", default: false, null: false
    t.string "repository_storages", default: "default"
    t.string "enabled_git_access_protocol"
    t.boolean "domain_blacklist_enabled", default: false
    t.text "domain_blacklist"
    t.boolean "usage_ping_enabled", default: true, null: false
    t.text "sign_in_text_html"
    t.text "help_page_text_html"
    t.text "shared_runners_text_html"
    t.text "after_sign_up_text_html"
    t.integer "rsa_key_restriction", default: 0, null: false
    t.integer "dsa_key_restriction", default: -1, null: false
    t.integer "ecdsa_key_restriction", default: 0, null: false
    t.integer "ed25519_key_restriction", default: 0, null: false
    t.boolean "housekeeping_enabled", default: true, null: false
    t.boolean "housekeeping_bitmaps_enabled", default: true, null: false
    t.integer "housekeeping_incremental_repack_period", default: 10, null: false
    t.integer "housekeeping_full_repack_period", default: 50, null: false
    t.integer "housekeeping_gc_period", default: 200, null: false
    t.boolean "html_emails_enabled", default: true
    t.string "plantuml_url"
    t.boolean "plantuml_enabled"
    t.integer "terminal_max_session_time", default: 0, null: false
    t.integer "unique_ips_limit_per_user"
    t.integer "unique_ips_limit_time_window"
    t.boolean "unique_ips_limit_enabled", default: false, null: false
    t.string "default_artifacts_expire_in", default: "0", null: false
    t.string "uuid"
    t.decimal "polling_interval_multiplier", default: "1.0", null: false
    t.integer "cached_markdown_version"
    t.boolean "clientside_sentry_enabled", default: false, null: false
    t.string "clientside_sentry_dsn"
    t.boolean "prometheus_metrics_enabled", default: true, null: false
    t.boolean "help_page_hide_commercial_content", default: false
    t.string "help_page_support_url"
    t.integer "performance_bar_allowed_group_id"
    t.boolean "hashed_storage_enabled", default: false, null: false
    t.boolean "project_export_enabled", default: true, null: false
    t.boolean "auto_devops_enabled", default: true, null: false
    t.boolean "throttle_unauthenticated_enabled", default: false, null: false
    t.integer "throttle_unauthenticated_requests_per_period", default: 3600, null: false
    t.integer "throttle_unauthenticated_period_in_seconds", default: 3600, null: false
    t.boolean "throttle_authenticated_api_enabled", default: false, null: false
    t.integer "throttle_authenticated_api_requests_per_period", default: 7200, null: false
    t.integer "throttle_authenticated_api_period_in_seconds", default: 3600, null: false
    t.boolean "throttle_authenticated_web_enabled", default: false, null: false
    t.integer "throttle_authenticated_web_requests_per_period", default: 7200, null: false
    t.integer "throttle_authenticated_web_period_in_seconds", default: 3600, null: false
    t.boolean "password_authentication_enabled_for_web"
    t.boolean "password_authentication_enabled_for_git", default: true
    t.integer "gitaly_timeout_default", default: 55, null: false
    t.integer "gitaly_timeout_medium", default: 30, null: false
    t.integer "gitaly_timeout_fast", default: 10, null: false
    t.boolean "authorized_keys_enabled", default: true, null: false
    t.string "auto_devops_domain"
    t.boolean "pages_domain_verification_enabled", default: true, null: false
    t.string "user_default_internal_regex"
    t.boolean "allow_local_requests_from_hooks_and_services", default: false, null: false
    t.boolean "enforce_terms", default: false
    t.boolean "mirror_available", default: true, null: false
    t.boolean "hide_third_party_offers", default: false, null: false
    t.boolean "instance_statistics_visibility_private", default: false, null: false
    t.boolean "web_ide_clientside_preview_enabled", default: false, null: false
    t.boolean "user_show_add_ssh_key_message", default: true, null: false
    t.integer "usage_stats_set_by_user_id"
    t.integer "receive_max_input_size"
    t.integer "diff_max_patch_bytes", default: 102400, null: false
    t.integer "archive_builds_in_seconds"
    t.string "commit_email_hostname"
    t.boolean "protected_ci_variables", default: false, null: false
    t.string "runners_registration_token_encrypted"
    t.integer "local_markdown_version", default: 0, null: false
    t.integer "first_day_of_week", default: 0, null: false
    t.integer "default_project_creation", default: 2, null: false
    t.boolean "external_authorization_service_enabled", default: false, null: false
    t.string "external_authorization_service_url"
    t.string "external_authorization_service_default_label"
    t.float "external_authorization_service_timeout", default: 0.5
    t.text "external_auth_client_cert"
    t.text "encrypted_external_auth_client_key"
    t.string "encrypted_external_auth_client_key_iv"
    t.string "encrypted_external_auth_client_key_pass"
    t.string "encrypted_external_auth_client_key_pass_iv"
    t.string "lets_encrypt_notification_email"
    t.boolean "lets_encrypt_terms_of_service_accepted", default: false, null: false
    t.integer "elasticsearch_shards", default: 5, null: false
    t.integer "elasticsearch_replicas", default: 1, null: false
    t.text "encrypted_lets_encrypt_private_key"
    t.text "encrypted_lets_encrypt_private_key_iv"
    t.boolean "dns_rebinding_protection_enabled", default: true, null: false
    t.index ["usage_stats_set_by_user_id"], name: "index_application_settings_on_usage_stats_set_by_user_id", using: :btree
  end

  create_table "audit_events", id: :serial, force: :cascade do |t|
    t.integer "author_id", null: false
    t.string "type", null: false
    t.integer "entity_id", null: false
    t.string "entity_type", null: false
    t.text "details"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["entity_id", "entity_type"], name: "index_audit_events_on_entity_id_and_entity_type", using: :btree
  end

  create_table "award_emoji", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "user_id"
    t.integer "awardable_id"
    t.string "awardable_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["awardable_type", "awardable_id"], name: "index_award_emoji_on_awardable_type_and_awardable_id", using: :btree
    t.index ["user_id", "name"], name: "index_award_emoji_on_user_id_and_name", using: :btree
  end

  create_table "badges", id: :serial, force: :cascade do |t|
    t.string "link_url", null: false
    t.string "image_url", null: false
    t.integer "project_id"
    t.integer "group_id"
    t.string "type", null: false
    t.datetime_with_timezone "created_at", null: false
    t.datetime_with_timezone "updated_at", null: false
    t.index ["group_id"], name: "index_badges_on_group_id", using: :btree
    t.index ["project_id"], name: "index_badges_on_project_id", using: :btree
  end

  create_table "board_group_recent_visits", force: :cascade do |t|
    t.datetime_with_timezone "created_at", null: false
    t.datetime_with_timezone "updated_at", null: false
    t.integer "user_id"
    t.integer "board_id"
    t.integer "group_id"
    t.index ["board_id"], name: "index_board_group_recent_visits_on_board_id", using: :btree
    t.index ["group_id"], name: "index_board_group_recent_visits_on_group_id", using: :btree
    t.index ["user_id", "group_id", "board_id"], name: "index_board_group_recent_visits_on_user_group_and_board", unique: true, using: :btree
    t.index ["user_id"], name: "index_board_group_recent_visits_on_user_id", using: :btree
  end

  create_table "board_project_recent_visits", force: :cascade do |t|
    t.datetime_with_timezone "created_at", null: false
    t.datetime_with_timezone "updated_at", null: false
    t.integer "user_id"
    t.integer "project_id"
    t.integer "board_id"
    t.index ["board_id"], name: "index_board_project_recent_visits_on_board_id", using: :btree
    t.index ["project_id"], name: "index_board_project_recent_visits_on_project_id", using: :btree
    t.index ["user_id", "project_id", "board_id"], name: "index_board_project_recent_visits_on_user_project_and_board", unique: true, using: :btree
    t.index ["user_id"], name: "index_board_project_recent_visits_on_user_id", using: :btree
  end

  create_table "boards", id: :serial, force: :cascade do |t|
    t.integer "project_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "group_id"
    t.index ["group_id"], name: "index_boards_on_group_id", using: :btree
    t.index ["project_id"], name: "index_boards_on_project_id", using: :btree
  end

  create_table "broadcast_messages", id: :serial, force: :cascade do |t|
    t.text "message", null: false
    t.datetime "starts_at", null: false
    t.datetime "ends_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "color"
    t.string "font"
    t.text "message_html", null: false
    t.integer "cached_markdown_version"
    t.index ["starts_at", "ends_at", "id"], name: "index_broadcast_messages_on_starts_at_and_ends_at_and_id", using: :btree
  end

  create_table "chat_names", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "service_id", null: false
    t.string "team_id", null: false
    t.string "team_domain"
    t.string "chat_id", null: false
    t.string "chat_name"
    t.datetime "last_used_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["service_id", "team_id", "chat_id"], name: "index_chat_names_on_service_id_and_team_id_and_chat_id", unique: true, using: :btree
    t.index ["user_id", "service_id"], name: "index_chat_names_on_user_id_and_service_id", unique: true, using: :btree
  end

  create_table "chat_teams", id: :serial, force: :cascade do |t|
    t.integer "namespace_id", null: false
    t.string "team_id"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["namespace_id"], name: "index_chat_teams_on_namespace_id", unique: true, using: :btree
  end

  create_table "ci_build_trace_chunks", force: :cascade do |t|
    t.integer "build_id", null: false
    t.integer "chunk_index", null: false
    t.integer "data_store", null: false
    t.binary "raw_data"
    t.index ["build_id", "chunk_index"], name: "index_ci_build_trace_chunks_on_build_id_and_chunk_index", unique: true, using: :btree
  end

  create_table "ci_build_trace_section_names", id: :serial, force: :cascade do |t|
    t.integer "project_id", null: false
    t.string "name", null: false
    t.index ["project_id", "name"], name: "index_ci_build_trace_section_names_on_project_id_and_name", unique: true, using: :btree
  end

  create_table "ci_build_trace_sections", id: :serial, force: :cascade do |t|
    t.integer "project_id", null: false
    t.datetime_with_timezone "date_start", null: false
    t.datetime_with_timezone "date_end", null: false
    t.bigint "byte_start", null: false
    t.bigint "byte_end", null: false
    t.integer "build_id", null: false
    t.integer "section_name_id", null: false
    t.index ["build_id", "section_name_id"], name: "index_ci_build_trace_sections_on_build_id_and_section_name_id", unique: true, using: :btree
    t.index ["project_id"], name: "index_ci_build_trace_sections_on_project_id", using: :btree
    t.index ["section_name_id"], name: "index_ci_build_trace_sections_on_section_name_id", using: :btree
  end

  create_table "ci_builds", id: :serial, force: :cascade do |t|
    t.string "status"
    t.datetime "finished_at"
    t.text "trace"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "started_at"
    t.integer "runner_id"
    t.float "coverage"
    t.integer "commit_id"
    t.text "commands"
    t.string "name"
    t.text "options"
    t.boolean "allow_failure", default: false, null: false
    t.string "stage"
    t.integer "trigger_request_id"
    t.integer "stage_idx"
    t.boolean "tag"
    t.string "ref"
    t.integer "user_id"
    t.string "type"
    t.string "target_url"
    t.string "description"
    t.text "artifacts_file"
    t.integer "project_id"
    t.text "artifacts_metadata"
    t.integer "erased_by_id"
    t.datetime "erased_at"
    t.datetime "artifacts_expire_at"
    t.string "environment"
    t.bigint "artifacts_size"
    t.string "when"
    t.text "yaml_variables"
    t.datetime "queued_at"
    t.string "token"
    t.integer "lock_version"
    t.string "coverage_regex"
    t.integer "auto_canceled_by_id"
    t.boolean "retried"
    t.integer "stage_id"
    t.integer "artifacts_file_store"
    t.integer "artifacts_metadata_store"
    t.boolean "protected"
    t.integer "failure_reason"
    t.datetime_with_timezone "scheduled_at"
    t.string "token_encrypted"
    t.index ["artifacts_expire_at"], name: "index_ci_builds_on_artifacts_expire_at", where: "(artifacts_file <> ''::text)", using: :btree
    t.index ["auto_canceled_by_id"], name: "index_ci_builds_on_auto_canceled_by_id", using: :btree
    t.index ["commit_id", "artifacts_expire_at", "id"], name: "index_ci_builds_on_commit_id_and_artifacts_expireatandidpartial", where: "(((type)::text = 'Ci::Build'::text) AND ((retried = false) OR (retried IS NULL)) AND ((name)::text = ANY (ARRAY[('sast'::character varying)::text, ('dependency_scanning'::character varying)::text, ('sast:container'::character varying)::text, ('container_scanning'::character varying)::text, ('dast'::character varying)::text])))", using: :btree
    t.index ["commit_id", "stage_idx", "created_at"], name: "index_ci_builds_on_commit_id_and_stage_idx_and_created_at", using: :btree
    t.index ["commit_id", "status", "type"], name: "index_ci_builds_on_commit_id_and_status_and_type", using: :btree
    t.index ["commit_id", "type", "name", "ref"], name: "index_ci_builds_on_commit_id_and_type_and_name_and_ref", using: :btree
    t.index ["commit_id", "type", "ref"], name: "index_ci_builds_on_commit_id_and_type_and_ref", using: :btree
    t.index ["project_id", "id"], name: "index_ci_builds_on_project_id_and_id", using: :btree
    t.index ["project_id", "status"], name: "index_ci_builds_project_id_and_status_for_live_jobs_partial2", where: "(((type)::text = 'Ci::Build'::text) AND ((status)::text = ANY (ARRAY[('running'::character varying)::text, ('pending'::character varying)::text, ('created'::character varying)::text])))", using: :btree
    t.index ["protected"], name: "index_ci_builds_on_protected", using: :btree
    t.index ["queued_at"], name: "index_ci_builds_on_queued_at", using: :btree
    t.index ["runner_id"], name: "index_ci_builds_on_runner_id", using: :btree
    t.index ["scheduled_at"], name: "partial_index_ci_builds_on_scheduled_at_with_scheduled_jobs", where: "((scheduled_at IS NOT NULL) AND ((type)::text = 'Ci::Build'::text) AND ((status)::text = 'scheduled'::text))", using: :btree
    t.index ["stage_id", "stage_idx"], name: "tmp_build_stage_position_index", where: "(stage_idx IS NOT NULL)", using: :btree
    t.index ["stage_id"], name: "index_ci_builds_on_stage_id", using: :btree
    t.index ["status", "type", "runner_id"], name: "index_ci_builds_on_status_and_type_and_runner_id", using: :btree
    t.index ["token"], name: "index_ci_builds_on_token", unique: true, using: :btree
    t.index ["token_encrypted"], name: "index_ci_builds_on_token_encrypted", unique: true, where: "(token_encrypted IS NOT NULL)", using: :btree
    t.index ["updated_at"], name: "index_ci_builds_on_updated_at", using: :btree
    t.index ["user_id"], name: "index_ci_builds_on_user_id", using: :btree
  end

  create_table "ci_builds_metadata", id: :serial, force: :cascade do |t|
    t.integer "build_id", null: false
    t.integer "project_id", null: false
    t.integer "timeout"
    t.integer "timeout_source", default: 1, null: false
    t.jsonb "config_options"
    t.jsonb "config_variables"
    t.index ["build_id"], name: "index_ci_builds_metadata_on_build_id", unique: true, using: :btree
    t.index ["project_id"], name: "index_ci_builds_metadata_on_project_id", using: :btree
  end

  create_table "ci_builds_runner_session", force: :cascade do |t|
    t.integer "build_id", null: false
    t.string "url", null: false
    t.string "certificate"
    t.string "authorization"
    t.index ["build_id"], name: "index_ci_builds_runner_session_on_build_id", unique: true, using: :btree
  end

  create_table "ci_group_variables", id: :serial, force: :cascade do |t|
    t.string "key", null: false
    t.text "value"
    t.text "encrypted_value"
    t.string "encrypted_value_salt"
    t.string "encrypted_value_iv"
    t.integer "group_id", null: false
    t.boolean "protected", default: false, null: false
    t.datetime_with_timezone "created_at", null: false
    t.datetime_with_timezone "updated_at", null: false
    t.boolean "masked", default: false, null: false
    t.integer "variable_type", limit: 2, default: 1, null: false
    t.index ["group_id", "key"], name: "index_ci_group_variables_on_group_id_and_key", unique: true, using: :btree
  end

  create_table "ci_job_artifacts", id: :serial, force: :cascade do |t|
    t.integer "project_id", null: false
    t.integer "job_id", null: false
    t.integer "file_type", null: false
    t.integer "file_store"
    t.bigint "size"
    t.datetime_with_timezone "created_at", null: false
    t.datetime_with_timezone "updated_at", null: false
    t.datetime_with_timezone "expire_at"
    t.string "file"
    t.binary "file_sha256"
    t.integer "file_format", limit: 2
    t.integer "file_location", limit: 2
    t.index ["expire_at", "job_id"], name: "index_ci_job_artifacts_on_expire_at_and_job_id", using: :btree
    t.index ["file_store"], name: "index_ci_job_artifacts_on_file_store", using: :btree
    t.index ["job_id", "file_type"], name: "index_ci_job_artifacts_on_job_id_and_file_type", unique: true, using: :btree
    t.index ["project_id"], name: "index_ci_job_artifacts_on_project_id", using: :btree
  end

  create_table "ci_pipeline_chat_data", force: :cascade do |t|
    t.integer "pipeline_id", null: false
    t.integer "chat_name_id", null: false
    t.text "response_url", null: false
    t.index ["chat_name_id"], name: "index_ci_pipeline_chat_data_on_chat_name_id", using: :btree
    t.index ["pipeline_id"], name: "index_ci_pipeline_chat_data_on_pipeline_id", unique: true, using: :btree
  end

  create_table "ci_pipeline_schedule_variables", force: :cascade do |t|
    t.string "key", null: false
    t.text "value"
    t.text "encrypted_value"
    t.string "encrypted_value_salt"
    t.string "encrypted_value_iv"
    t.integer "pipeline_schedule_id", null: false
    t.datetime_with_timezone "created_at"
    t.datetime_with_timezone "updated_at"
    t.integer "variable_type", limit: 2, default: 1, null: false
    t.index ["pipeline_schedule_id", "key"], name: "index_ci_pipeline_schedule_variables_on_schedule_id_and_key", unique: true, using: :btree
  end

  create_table "ci_pipeline_schedules", id: :serial, force: :cascade do |t|
    t.string "description"
    t.string "ref"
    t.string "cron"
    t.string "cron_timezone"
    t.datetime "next_run_at"
    t.integer "project_id"
    t.integer "owner_id"
    t.boolean "active", default: true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["next_run_at", "active"], name: "index_ci_pipeline_schedules_on_next_run_at_and_active", using: :btree
    t.index ["owner_id"], name: "index_ci_pipeline_schedules_on_owner_id", using: :btree
    t.index ["project_id"], name: "index_ci_pipeline_schedules_on_project_id", using: :btree
  end

  create_table "ci_pipeline_variables", id: :serial, force: :cascade do |t|
    t.string "key", null: false
    t.text "value"
    t.text "encrypted_value"
    t.string "encrypted_value_salt"
    t.string "encrypted_value_iv"
    t.integer "pipeline_id", null: false
    t.integer "variable_type", limit: 2, default: 1, null: false
    t.index ["pipeline_id", "key"], name: "index_ci_pipeline_variables_on_pipeline_id_and_key", unique: true, using: :btree
  end

  create_table "ci_pipelines", id: :serial, force: :cascade do |t|
    t.string "ref"
    t.string "sha"
    t.string "before_sha"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "tag", default: false
    t.text "yaml_errors"
    t.datetime "committed_at"
    t.integer "project_id"
    t.string "status"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.integer "duration"
    t.integer "user_id"
    t.integer "lock_version"
    t.integer "auto_canceled_by_id"
    t.integer "pipeline_schedule_id"
    t.integer "source"
    t.integer "config_source"
    t.boolean "protected"
    t.integer "failure_reason"
    t.integer "iid"
    t.integer "merge_request_id"
    t.binary "source_sha"
    t.binary "target_sha"
    t.index ["auto_canceled_by_id"], name: "index_ci_pipelines_on_auto_canceled_by_id", using: :btree
    t.index ["merge_request_id"], name: "index_ci_pipelines_on_merge_request_id", where: "(merge_request_id IS NOT NULL)", using: :btree
    t.index ["pipeline_schedule_id"], name: "index_ci_pipelines_on_pipeline_schedule_id", using: :btree
    t.index ["project_id", "iid"], name: "index_ci_pipelines_on_project_id_and_iid", unique: true, where: "(iid IS NOT NULL)", using: :btree
    t.index ["project_id", "ref", "id"], name: "index_ci_pipelines_on_project_idandrefandiddesc", order: { id: :desc }, using: :btree
    t.index ["project_id", "ref", "status", "id"], name: "index_ci_pipelines_on_project_id_and_ref_and_status_and_id", using: :btree
    t.index ["project_id", "sha"], name: "index_ci_pipelines_on_project_id_and_sha", using: :btree
    t.index ["project_id", "source"], name: "index_ci_pipelines_on_project_id_and_source", using: :btree
    t.index ["project_id", "status", "config_source"], name: "index_ci_pipelines_on_project_id_and_status_and_config_source", using: :btree
    t.index ["project_id"], name: "index_ci_pipelines_on_project_id", using: :btree
    t.index ["status"], name: "index_ci_pipelines_on_status", using: :btree
    t.index ["user_id"], name: "index_ci_pipelines_on_user_id", using: :btree
  end

  create_table "ci_runner_namespaces", id: :serial, force: :cascade do |t|
    t.integer "runner_id"
    t.integer "namespace_id"
    t.index ["namespace_id"], name: "index_ci_runner_namespaces_on_namespace_id", using: :btree
    t.index ["runner_id", "namespace_id"], name: "index_ci_runner_namespaces_on_runner_id_and_namespace_id", unique: true, using: :btree
  end

  create_table "ci_runner_projects", id: :serial, force: :cascade do |t|
    t.integer "runner_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "project_id"
    t.index ["project_id"], name: "index_ci_runner_projects_on_project_id", using: :btree
    t.index ["runner_id"], name: "index_ci_runner_projects_on_runner_id", using: :btree
  end

  create_table "ci_runners", id: :serial, force: :cascade do |t|
    t.string "token"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "description"
    t.datetime "contacted_at"
    t.boolean "active", default: true, null: false
    t.boolean "is_shared", default: false
    t.string "name"
    t.string "version"
    t.string "revision"
    t.string "platform"
    t.string "architecture"
    t.boolean "run_untagged", default: true, null: false
    t.boolean "locked", default: false, null: false
    t.integer "access_level", default: 0, null: false
    t.string "ip_address"
    t.integer "maximum_timeout"
    t.integer "runner_type", limit: 2, null: false
    t.string "token_encrypted"
    t.index ["contacted_at"], name: "index_ci_runners_on_contacted_at", using: :btree
    t.index ["is_shared"], name: "index_ci_runners_on_is_shared", using: :btree
    t.index ["locked"], name: "index_ci_runners_on_locked", using: :btree
    t.index ["runner_type"], name: "index_ci_runners_on_runner_type", using: :btree
    t.index ["token"], name: "index_ci_runners_on_token", using: :btree
    t.index ["token_encrypted"], name: "index_ci_runners_on_token_encrypted", using: :btree
  end

  create_table "ci_stages", id: :serial, force: :cascade do |t|
    t.integer "project_id"
    t.integer "pipeline_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "name"
    t.integer "status"
    t.integer "lock_version"
    t.integer "position"
    t.index ["pipeline_id", "name"], name: "index_ci_stages_on_pipeline_id_and_name", unique: true, using: :btree
    t.index ["pipeline_id", "position"], name: "index_ci_stages_on_pipeline_id_and_position", using: :btree
    t.index ["pipeline_id"], name: "index_ci_stages_on_pipeline_id", using: :btree
    t.index ["project_id"], name: "index_ci_stages_on_project_id", using: :btree
  end

  create_table "ci_trigger_requests", id: :serial, force: :cascade do |t|
    t.integer "trigger_id", null: false
    t.text "variables"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "commit_id"
    t.index ["commit_id"], name: "index_ci_trigger_requests_on_commit_id", using: :btree
    t.index ["trigger_id"], name: "index_ci_trigger_requests_on_trigger_id", using: :btree
  end

  create_table "ci_triggers", id: :serial, force: :cascade do |t|
    t.string "token"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "project_id"
    t.integer "owner_id"
    t.string "description"
    t.string "ref"
    t.index ["owner_id"], name: "index_ci_triggers_on_owner_id", using: :btree
    t.index ["project_id"], name: "index_ci_triggers_on_project_id", using: :btree
  end

  create_table "ci_variables", id: :serial, force: :cascade do |t|
    t.string "key", null: false
    t.text "value"
    t.text "encrypted_value"
    t.string "encrypted_value_salt"
    t.string "encrypted_value_iv"
    t.integer "project_id", null: false
    t.boolean "protected", default: false, null: false
    t.string "environment_scope", default: "*", null: false
    t.boolean "masked", default: false, null: false
    t.integer "variable_type", limit: 2, default: 1, null: false
    t.index ["project_id", "key", "environment_scope"], name: "index_ci_variables_on_project_id_and_key_and_environment_scope", unique: true, using: :btree
  end

  create_table "cluster_groups", id: :serial, force: :cascade do |t|
    t.integer "cluster_id", null: false
    t.integer "group_id", null: false
    t.index ["cluster_id", "group_id"], name: "index_cluster_groups_on_cluster_id_and_group_id", unique: true, using: :btree
    t.index ["group_id"], name: "index_cluster_groups_on_group_id", using: :btree
  end

  create_table "cluster_platforms_kubernetes", id: :serial, force: :cascade do |t|
    t.integer "cluster_id", null: false
    t.datetime_with_timezone "created_at", null: false
    t.datetime_with_timezone "updated_at", null: false
    t.text "api_url"
    t.text "ca_cert"
    t.string "namespace"
    t.string "username"
    t.text "encrypted_password"
    t.string "encrypted_password_iv"
    t.text "encrypted_token"
    t.string "encrypted_token_iv"
    t.integer "authorization_type", limit: 2
    t.index ["cluster_id"], name: "index_cluster_platforms_kubernetes_on_cluster_id", unique: true, using: :btree
  end

  create_table "cluster_projects", id: :serial, force: :cascade do |t|
    t.integer "project_id", null: false
    t.integer "cluster_id", null: false
    t.datetime_with_timezone "created_at", null: false
    t.datetime_with_timezone "updated_at", null: false
    t.index ["cluster_id"], name: "index_cluster_projects_on_cluster_id", using: :btree
    t.index ["project_id"], name: "index_cluster_projects_on_project_id", using: :btree
  end

  create_table "cluster_providers_gcp", id: :serial, force: :cascade do |t|
    t.integer "cluster_id", null: false
    t.integer "status"
    t.integer "num_nodes", null: false
    t.datetime_with_timezone "created_at", null: false
    t.datetime_with_timezone "updated_at", null: false
    t.text "status_reason"
    t.string "gcp_project_id", null: false
    t.string "zone", null: false
    t.string "machine_type"
    t.string "operation_id"
    t.string "endpoint"
    t.text "encrypted_access_token"
    t.string "encrypted_access_token_iv"
    t.boolean "legacy_abac", default: false, null: false
    t.index ["cluster_id"], name: "index_cluster_providers_gcp_on_cluster_id", unique: true, using: :btree
  end

  create_table "clusters", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "provider_type"
    t.integer "platform_type"
    t.datetime_with_timezone "created_at", null: false
    t.datetime_with_timezone "updated_at", null: false
    t.boolean "enabled", default: true
    t.string "name", null: false
    t.string "environment_scope", default: "*", null: false
    t.integer "cluster_type", limit: 2, default: 3, null: false
    t.string "domain"
    t.boolean "managed", default: true, null: false
    t.index ["enabled"], name: "index_clusters_on_enabled", using: :btree
    t.index ["user_id"], name: "index_clusters_on_user_id", using: :btree
  end

  create_table "clusters_applications_cert_managers", id: :serial, force: :cascade do |t|
    t.integer "cluster_id", null: false
    t.integer "status", null: false
    t.string "version", null: false
    t.string "email", null: false
    t.datetime_with_timezone "created_at", null: false
    t.datetime_with_timezone "updated_at", null: false
    t.text "status_reason"
    t.index ["cluster_id"], name: "index_clusters_applications_cert_managers_on_cluster_id", unique: true, using: :btree
  end

  create_table "clusters_applications_helm", id: :serial, force: :cascade do |t|
    t.integer "cluster_id", null: false
    t.datetime_with_timezone "created_at", null: false
    t.datetime_with_timezone "updated_at", null: false
    t.integer "status", null: false
    t.string "version", null: false
    t.text "status_reason"
    t.text "encrypted_ca_key"
    t.text "encrypted_ca_key_iv"
    t.text "ca_cert"
    t.index ["cluster_id"], name: "index_clusters_applications_helm_on_cluster_id", unique: true, using: :btree
  end

  create_table "clusters_applications_ingress", id: :serial, force: :cascade do |t|
    t.integer "cluster_id", null: false
    t.datetime_with_timezone "created_at", null: false
    t.datetime_with_timezone "updated_at", null: false
    t.integer "status", null: false
    t.integer "ingress_type", null: false
    t.string "version", null: false
    t.string "cluster_ip"
    t.text "status_reason"
    t.string "external_ip"
    t.string "external_hostname"
    t.index ["cluster_id"], name: "index_clusters_applications_ingress_on_cluster_id", unique: true, using: :btree
  end

  create_table "clusters_applications_jupyter", id: :serial, force: :cascade do |t|
    t.integer "cluster_id", null: false
    t.integer "oauth_application_id"
    t.integer "status", null: false
    t.string "version", null: false
    t.string "hostname"
    t.datetime_with_timezone "created_at", null: false
    t.datetime_with_timezone "updated_at", null: false
    t.text "status_reason"
    t.index ["cluster_id"], name: "index_clusters_applications_jupyter_on_cluster_id", unique: true, using: :btree
    t.index ["oauth_application_id"], name: "index_clusters_applications_jupyter_on_oauth_application_id", using: :btree
  end

  create_table "clusters_applications_knative", id: :serial, force: :cascade do |t|
    t.integer "cluster_id", null: false
    t.datetime_with_timezone "created_at", null: false
    t.datetime_with_timezone "updated_at", null: false
    t.integer "status", null: false
    t.string "version", null: false
    t.string "hostname"
    t.text "status_reason"
    t.string "external_ip"
    t.string "external_hostname"
    t.index ["cluster_id"], name: "index_clusters_applications_knative_on_cluster_id", unique: true, using: :btree
  end

  create_table "clusters_applications_prometheus", id: :serial, force: :cascade do |t|
    t.integer "cluster_id", null: false
    t.integer "status", null: false
    t.string "version", null: false
    t.text "status_reason"
    t.datetime_with_timezone "created_at", null: false
    t.datetime_with_timezone "updated_at", null: false
    t.index ["cluster_id"], name: "index_clusters_applications_prometheus_on_cluster_id", unique: true, using: :btree
  end

  create_table "clusters_applications_runners", id: :serial, force: :cascade do |t|
    t.integer "cluster_id", null: false
    t.integer "runner_id"
    t.integer "status", null: false
    t.datetime_with_timezone "created_at", null: false
    t.datetime_with_timezone "updated_at", null: false
    t.string "version", null: false
    t.text "status_reason"
    t.boolean "privileged", default: true, null: false
    t.index ["cluster_id"], name: "index_clusters_applications_runners_on_cluster_id", unique: true, using: :btree
    t.index ["runner_id"], name: "index_clusters_applications_runners_on_runner_id", using: :btree
  end

  create_table "clusters_kubernetes_namespaces", force: :cascade do |t|
    t.integer "cluster_id", null: false
    t.integer "project_id"
    t.integer "cluster_project_id"
    t.datetime_with_timezone "created_at", null: false
    t.datetime_with_timezone "updated_at", null: false
    t.text "encrypted_service_account_token"
    t.string "encrypted_service_account_token_iv"
    t.string "namespace", null: false
    t.string "service_account_name"
    t.index ["cluster_id", "namespace"], name: "kubernetes_namespaces_cluster_and_namespace", unique: true, using: :btree
    t.index ["cluster_id"], name: "index_clusters_kubernetes_namespaces_on_cluster_id", using: :btree
    t.index ["cluster_project_id"], name: "index_clusters_kubernetes_namespaces_on_cluster_project_id", using: :btree
    t.index ["project_id"], name: "index_clusters_kubernetes_namespaces_on_project_id", using: :btree
  end

  create_table "container_repositories", id: :serial, force: :cascade do |t|
    t.integer "project_id", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id", "name"], name: "index_container_repositories_on_project_id_and_name", unique: true, using: :btree
    t.index ["project_id"], name: "index_container_repositories_on_project_id", using: :btree
  end

  create_table "conversational_development_index_metrics", id: :serial, force: :cascade do |t|
    t.float "leader_issues", null: false
    t.float "instance_issues", null: false
    t.float "leader_notes", null: false
    t.float "instance_notes", null: false
    t.float "leader_milestones", null: false
    t.float "instance_milestones", null: false
    t.float "leader_boards", null: false
    t.float "instance_boards", null: false
    t.float "leader_merge_requests", null: false
    t.float "instance_merge_requests", null: false
    t.float "leader_ci_pipelines", null: false
    t.float "instance_ci_pipelines", null: false
    t.float "leader_environments", null: false
    t.float "instance_environments", null: false
    t.float "leader_deployments", null: false
    t.float "instance_deployments", null: false
    t.float "leader_projects_prometheus_active", null: false
    t.float "instance_projects_prometheus_active", null: false
    t.float "leader_service_desk_issues", null: false
    t.float "instance_service_desk_issues", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "percentage_boards", default: 0.0, null: false
    t.float "percentage_ci_pipelines", default: 0.0, null: false
    t.float "percentage_deployments", default: 0.0, null: false
    t.float "percentage_environments", default: 0.0, null: false
    t.float "percentage_issues", default: 0.0, null: false
    t.float "percentage_merge_requests", default: 0.0, null: false
    t.float "percentage_milestones", default: 0.0, null: false
    t.float "percentage_notes", default: 0.0, null: false
    t.float "percentage_projects_prometheus_active", default: 0.0, null: false
    t.float "percentage_service_desk_issues", default: 0.0, null: false
  end

  create_table "deploy_keys_projects", id: :serial, force: :cascade do |t|
    t.integer "deploy_key_id", null: false
    t.integer "project_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "can_push", default: false, null: false
    t.index ["project_id"], name: "index_deploy_keys_projects_on_project_id", using: :btree
  end

  create_table "deploy_tokens", id: :serial, force: :cascade do |t|
    t.boolean "revoked", default: false
    t.boolean "read_repository", default: false, null: false
    t.boolean "read_registry", default: false, null: false
    t.datetime_with_timezone "expires_at", null: false
    t.datetime_with_timezone "created_at", null: false
    t.string "name", null: false
    t.string "token", null: false
    t.index ["token", "expires_at", "id"], name: "index_deploy_tokens_on_token_and_expires_at_and_id", where: "(revoked IS FALSE)", using: :btree
    t.index ["token"], name: "index_deploy_tokens_on_token", unique: true, using: :btree
  end

  create_table "deployments", id: :serial, force: :cascade do |t|
    t.integer "iid", null: false
    t.integer "project_id", null: false
    t.integer "environment_id", null: false
    t.string "ref", null: false
    t.boolean "tag", null: false
    t.string "sha", null: false
    t.integer "user_id"
    t.integer "deployable_id"
    t.string "deployable_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "on_stop"
    t.integer "status", limit: 2, null: false
    t.datetime_with_timezone "finished_at"
    t.index ["created_at"], name: "index_deployments_on_created_at", using: :btree
    t.index ["deployable_type", "deployable_id"], name: "index_deployments_on_deployable_type_and_deployable_id", using: :btree
    t.index ["environment_id", "id"], name: "index_deployments_on_environment_id_and_id", using: :btree
    t.index ["environment_id", "iid", "project_id"], name: "index_deployments_on_environment_id_and_iid_and_project_id", using: :btree
    t.index ["environment_id", "status"], name: "index_deployments_on_environment_id_and_status", using: :btree
    t.index ["id"], name: "partial_index_deployments_for_legacy_successful_deployments", where: "((finished_at IS NULL) AND (status = 2))", using: :btree
    t.index ["project_id", "iid"], name: "index_deployments_on_project_id_and_iid", unique: true, using: :btree
    t.index ["project_id", "status", "created_at"], name: "index_deployments_on_project_id_and_status_and_created_at", using: :btree
    t.index ["project_id", "status"], name: "index_deployments_on_project_id_and_status", using: :btree
  end

  create_table "emails", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "email", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "confirmation_token"
    t.datetime_with_timezone "confirmed_at"
    t.datetime_with_timezone "confirmation_sent_at"
    t.index ["confirmation_token"], name: "index_emails_on_confirmation_token", unique: true, using: :btree
    t.index ["email"], name: "index_emails_on_email", unique: true, using: :btree
    t.index ["user_id"], name: "index_emails_on_user_id", using: :btree
  end

  create_table "environments", id: :serial, force: :cascade do |t|
    t.integer "project_id", null: false
    t.string "name", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "external_url"
    t.string "environment_type"
    t.string "state", default: "available", null: false
    t.string "slug", null: false
    t.index ["project_id", "name"], name: "index_environments_on_project_id_and_name", unique: true, using: :btree
    t.index ["project_id", "slug"], name: "index_environments_on_project_id_and_slug", unique: true, using: :btree
  end

  create_table "events", id: :serial, force: :cascade do |t|
    t.integer "project_id"
    t.integer "author_id", null: false
    t.integer "target_id"
    t.datetime_with_timezone "created_at", null: false
    t.datetime_with_timezone "updated_at", null: false
    t.integer "action", limit: 2, null: false
    t.string "target_type"
    t.index ["action"], name: "index_events_on_action", using: :btree
    t.index ["author_id", "project_id"], name: "index_events_on_author_id_and_project_id", using: :btree
    t.index ["project_id", "created_at"], name: "index_events_on_project_id_and_created_at", using: :btree
    t.index ["project_id", "id"], name: "index_events_on_project_id_and_id", using: :btree
    t.index ["target_type", "target_id"], name: "index_events_on_target_type_and_target_id", using: :btree
  end

  create_table "feature_gates", id: :serial, force: :cascade do |t|
    t.string "feature_key", null: false
    t.string "key", null: false
    t.string "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["feature_key", "key", "value"], name: "index_feature_gates_on_feature_key_and_key_and_value", unique: true, using: :btree
  end

  create_table "features", id: :serial, force: :cascade do |t|
    t.string "key", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_features_on_key", unique: true, using: :btree
  end

  create_table "fork_network_members", id: :serial, force: :cascade do |t|
    t.integer "fork_network_id", null: false
    t.integer "project_id", null: false
    t.integer "forked_from_project_id"
    t.index ["fork_network_id"], name: "index_fork_network_members_on_fork_network_id", using: :btree
    t.index ["forked_from_project_id"], name: "index_fork_network_members_on_forked_from_project_id", using: :btree
    t.index ["project_id"], name: "index_fork_network_members_on_project_id", unique: true, using: :btree
  end

  create_table "fork_networks", id: :serial, force: :cascade do |t|
    t.integer "root_project_id"
    t.string "deleted_root_project_name"
    t.index ["root_project_id"], name: "index_fork_networks_on_root_project_id", unique: true, using: :btree
  end

  create_table "forked_project_links", id: :serial, force: :cascade do |t|
    t.integer "forked_to_project_id", null: false
    t.integer "forked_from_project_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["forked_to_project_id"], name: "index_forked_project_links_on_forked_to_project_id", unique: true, using: :btree
  end

  create_table "gpg_key_subkeys", id: :serial, force: :cascade do |t|
    t.integer "gpg_key_id", null: false
    t.binary "keyid"
    t.binary "fingerprint"
    t.index ["fingerprint"], name: "index_gpg_key_subkeys_on_fingerprint", unique: true, using: :btree
    t.index ["gpg_key_id"], name: "index_gpg_key_subkeys_on_gpg_key_id", using: :btree
    t.index ["keyid"], name: "index_gpg_key_subkeys_on_keyid", unique: true, using: :btree
  end

  create_table "gpg_keys", id: :serial, force: :cascade do |t|
    t.datetime_with_timezone "created_at", null: false
    t.datetime_with_timezone "updated_at", null: false
    t.integer "user_id"
    t.binary "primary_keyid"
    t.binary "fingerprint"
    t.text "key"
    t.index ["fingerprint"], name: "index_gpg_keys_on_fingerprint", unique: true, using: :btree
    t.index ["primary_keyid"], name: "index_gpg_keys_on_primary_keyid", unique: true, using: :btree
    t.index ["user_id"], name: "index_gpg_keys_on_user_id", using: :btree
  end

  create_table "gpg_signatures", id: :serial, force: :cascade do |t|
    t.datetime_with_timezone "created_at", null: false
    t.datetime_with_timezone "updated_at", null: false
    t.integer "project_id"
    t.integer "gpg_key_id"
    t.binary "commit_sha"
    t.binary "gpg_key_primary_keyid"
    t.text "gpg_key_user_name"
    t.text "gpg_key_user_email"
    t.integer "verification_status", limit: 2, default: 0, null: false
    t.integer "gpg_key_subkey_id"
    t.index ["commit_sha"], name: "index_gpg_signatures_on_commit_sha", unique: true, using: :btree
    t.index ["gpg_key_id"], name: "index_gpg_signatures_on_gpg_key_id", using: :btree
    t.index ["gpg_key_primary_keyid"], name: "index_gpg_signatures_on_gpg_key_primary_keyid", using: :btree
    t.index ["gpg_key_subkey_id"], name: "index_gpg_signatures_on_gpg_key_subkey_id", using: :btree
    t.index ["project_id"], name: "index_gpg_signatures_on_project_id", using: :btree
  end

  create_table "group_custom_attributes", id: :serial, force: :cascade do |t|
    t.datetime_with_timezone "created_at", null: false
    t.datetime_with_timezone "updated_at", null: false
    t.integer "group_id", null: false
    t.string "key", null: false
    t.string "value", null: false
    t.index ["group_id", "key"], name: "index_group_custom_attributes_on_group_id_and_key", unique: true, using: :btree
    t.index ["key", "value"], name: "index_group_custom_attributes_on_key_and_value", using: :btree
  end

  create_table "identities", id: :serial, force: :cascade do |t|
    t.string "extern_uid"
    t.string "provider"
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["user_id"], name: "index_identities_on_user_id", using: :btree
  end

  create_table "import_export_uploads", id: :serial, force: :cascade do |t|
    t.datetime_with_timezone "updated_at", null: false
    t.integer "project_id"
    t.text "import_file"
    t.text "export_file"
    t.index ["project_id"], name: "index_import_export_uploads_on_project_id", using: :btree
    t.index ["updated_at"], name: "index_import_export_uploads_on_updated_at", using: :btree
  end

  create_table "internal_ids", force: :cascade do |t|
    t.integer "project_id"
    t.integer "usage", null: false
    t.integer "last_value", null: false
    t.integer "namespace_id"
    t.index ["namespace_id"], name: "index_internal_ids_on_namespace_id", using: :btree
    t.index ["project_id"], name: "index_internal_ids_on_project_id", using: :btree
    t.index ["usage", "namespace_id"], name: "index_internal_ids_on_usage_and_namespace_id", unique: true, where: "(namespace_id IS NOT NULL)", using: :btree
    t.index ["usage", "project_id"], name: "index_internal_ids_on_usage_and_project_id", unique: true, where: "(project_id IS NOT NULL)", using: :btree
  end

  create_table "issue_assignees", id: false, force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "issue_id", null: false
    t.index ["issue_id", "user_id"], name: "index_issue_assignees_on_issue_id_and_user_id", unique: true, using: :btree
    t.index ["user_id"], name: "index_issue_assignees_on_user_id", using: :btree
  end

  create_table "issue_metrics", id: :serial, force: :cascade do |t|
    t.integer "issue_id", null: false
    t.datetime "first_mentioned_in_commit_at"
    t.datetime "first_associated_with_milestone_at"
    t.datetime "first_added_to_board_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["issue_id"], name: "index_issue_metrics", using: :btree
  end

  create_table "issues", id: :serial, force: :cascade do |t|
    t.string "title"
    t.integer "author_id"
    t.integer "project_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "description"
    t.integer "milestone_id"
    t.string "state"
    t.integer "iid"
    t.integer "updated_by_id"
    t.boolean "confidential", default: false, null: false
    t.date "due_date"
    t.integer "moved_to_id"
    t.integer "lock_version"
    t.text "title_html"
    t.text "description_html"
    t.integer "time_estimate"
    t.integer "relative_position"
    t.integer "cached_markdown_version"
    t.datetime "last_edited_at"
    t.integer "last_edited_by_id"
    t.boolean "discussion_locked"
    t.datetime_with_timezone "closed_at"
    t.integer "closed_by_id"
    t.integer "state_id", limit: 2
    t.index ["author_id"], name: "index_issues_on_author_id", using: :btree
    t.index ["closed_by_id"], name: "index_issues_on_closed_by_id", using: :btree
    t.index ["confidential"], name: "index_issues_on_confidential", using: :btree
    t.index ["description"], name: "index_issues_on_description_trigram", using: :gin, opclasses: {"description"=>"gin_trgm_ops"}
    t.index ["milestone_id"], name: "index_issues_on_milestone_id", using: :btree
    t.index ["moved_to_id"], name: "index_issues_on_moved_to_id", where: "(moved_to_id IS NOT NULL)", using: :btree
    t.index ["project_id", "created_at", "id", "state"], name: "index_issues_on_project_id_and_created_at_and_id_and_state", using: :btree
    t.index ["project_id", "due_date", "id", "state"], name: "idx_issues_on_project_id_and_due_date_and_id_and_state_partial", where: "(due_date IS NOT NULL)", using: :btree
    t.index ["project_id", "iid"], name: "index_issues_on_project_id_and_iid", unique: true, using: :btree
    t.index ["project_id", "updated_at", "id", "state"], name: "index_issues_on_project_id_and_updated_at_and_id_and_state", using: :btree
    t.index ["relative_position"], name: "index_issues_on_relative_position", using: :btree
    t.index ["state"], name: "index_issues_on_state", using: :btree
    t.index ["title"], name: "index_issues_on_title_trigram", using: :gin, opclasses: {"title"=>"gin_trgm_ops"}
    t.index ["updated_at"], name: "index_issues_on_updated_at", using: :btree
    t.index ["updated_by_id"], name: "index_issues_on_updated_by_id", where: "(updated_by_id IS NOT NULL)", using: :btree
  end

  create_table "keys", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "key"
    t.string "title"
    t.string "type"
    t.string "fingerprint"
    t.boolean "public", default: false, null: false
    t.datetime "last_used_at"
    t.index ["fingerprint"], name: "index_keys_on_fingerprint", unique: true, using: :btree
    t.index ["user_id"], name: "index_keys_on_user_id", using: :btree
  end

  create_table "label_links", id: :serial, force: :cascade do |t|
    t.integer "label_id"
    t.integer "target_id"
    t.string "target_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["label_id"], name: "index_label_links_on_label_id", using: :btree
    t.index ["target_id", "target_type"], name: "index_label_links_on_target_id_and_target_type", using: :btree
  end

  create_table "label_priorities", id: :serial, force: :cascade do |t|
    t.integer "project_id", null: false
    t.integer "label_id", null: false
    t.integer "priority", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["label_id"], name: "index_label_priorities_on_label_id", using: :btree
    t.index ["priority"], name: "index_label_priorities_on_priority", using: :btree
    t.index ["project_id", "label_id"], name: "index_label_priorities_on_project_id_and_label_id", unique: true, using: :btree
  end

  create_table "labels", id: :serial, force: :cascade do |t|
    t.string "title"
    t.string "color"
    t.integer "project_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "template", default: false
    t.string "description"
    t.text "description_html"
    t.string "type"
    t.integer "group_id"
    t.integer "cached_markdown_version"
    t.index ["group_id", "project_id", "title"], name: "index_labels_on_group_id_and_project_id_and_title", unique: true, using: :btree
    t.index ["project_id"], name: "index_labels_on_project_id", using: :btree
    t.index ["template"], name: "index_labels_on_template", where: "template", using: :btree
    t.index ["title"], name: "index_labels_on_title", using: :btree
    t.index ["type", "project_id"], name: "index_labels_on_type_and_project_id", using: :btree
  end

  create_table "lfs_file_locks", id: :serial, force: :cascade do |t|
    t.integer "project_id", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.string "path", limit: 511
    t.index ["project_id", "path"], name: "index_lfs_file_locks_on_project_id_and_path", unique: true, using: :btree
    t.index ["user_id"], name: "index_lfs_file_locks_on_user_id", using: :btree
  end

  create_table "lfs_objects", id: :serial, force: :cascade do |t|
    t.string "oid", null: false
    t.bigint "size", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "file"
    t.integer "file_store"
    t.index ["file_store"], name: "index_lfs_objects_on_file_store", using: :btree
    t.index ["oid"], name: "index_lfs_objects_on_oid", unique: true, using: :btree
  end

  create_table "lfs_objects_projects", id: :serial, force: :cascade do |t|
    t.integer "lfs_object_id", null: false
    t.integer "project_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["project_id"], name: "index_lfs_objects_projects_on_project_id", using: :btree
  end

  create_table "lists", id: :serial, force: :cascade do |t|
    t.integer "board_id", null: false
    t.integer "label_id"
    t.integer "list_type", default: 1, null: false
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["board_id", "label_id"], name: "index_lists_on_board_id_and_label_id", unique: true, using: :btree
    t.index ["label_id"], name: "index_lists_on_label_id", using: :btree
    t.index ["list_type"], name: "index_lists_on_list_type", using: :btree
  end

  create_table "members", id: :serial, force: :cascade do |t|
    t.integer "access_level", null: false
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.integer "user_id"
    t.integer "notification_level", null: false
    t.string "type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "created_by_id"
    t.string "invite_email"
    t.string "invite_token"
    t.datetime "invite_accepted_at"
    t.datetime "requested_at"
    t.date "expires_at"
    t.index ["access_level"], name: "index_members_on_access_level", using: :btree
    t.index ["invite_token"], name: "index_members_on_invite_token", unique: true, using: :btree
    t.index ["requested_at"], name: "index_members_on_requested_at", using: :btree
    t.index ["source_id", "source_type"], name: "index_members_on_source_id_and_source_type", using: :btree
    t.index ["user_id"], name: "index_members_on_user_id", using: :btree
  end

  create_table "merge_request_assignees", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "merge_request_id", null: false
    t.index ["merge_request_id", "user_id"], name: "index_merge_request_assignees_on_merge_request_id_and_user_id", unique: true, using: :btree
    t.index ["merge_request_id"], name: "index_merge_request_assignees_on_merge_request_id", using: :btree
    t.index ["user_id"], name: "index_merge_request_assignees_on_user_id", using: :btree
  end

  create_table "merge_request_blocks", force: :cascade do |t|
    t.integer "blocking_merge_request_id", null: false
    t.integer "blocked_merge_request_id", null: false
    t.datetime_with_timezone "created_at", null: false
    t.datetime_with_timezone "updated_at", null: false
    t.index ["blocked_merge_request_id"], name: "index_merge_request_blocks_on_blocked_merge_request_id", using: :btree
    t.index ["blocking_merge_request_id", "blocked_merge_request_id"], name: "index_mr_blocks_on_blocking_and_blocked_mr_ids", unique: true, using: :btree
  end

  create_table "merge_request_diff_commits", id: false, force: :cascade do |t|
    t.datetime_with_timezone "authored_date"
    t.datetime_with_timezone "committed_date"
    t.integer "merge_request_diff_id", null: false
    t.integer "relative_order", null: false
    t.binary "sha", null: false
    t.text "author_name"
    t.text "author_email"
    t.text "committer_name"
    t.text "committer_email"
    t.text "message"
    t.index ["merge_request_diff_id", "relative_order"], name: "index_merge_request_diff_commits_on_mr_diff_id_and_order", unique: true, using: :btree
    t.index ["sha"], name: "index_merge_request_diff_commits_on_sha", using: :btree
  end

  create_table "merge_request_diff_files", id: false, force: :cascade do |t|
    t.integer "merge_request_diff_id", null: false
    t.integer "relative_order", null: false
    t.boolean "new_file", null: false
    t.boolean "renamed_file", null: false
    t.boolean "deleted_file", null: false
    t.boolean "too_large", null: false
    t.string "a_mode", null: false
    t.string "b_mode", null: false
    t.text "new_path", null: false
    t.text "old_path", null: false
    t.text "diff"
    t.boolean "binary"
    t.integer "external_diff_offset"
    t.integer "external_diff_size"
    t.index ["merge_request_diff_id", "relative_order"], name: "index_merge_request_diff_files_on_mr_diff_id_and_order", unique: true, using: :btree
  end

  create_table "merge_request_diffs", id: :serial, force: :cascade do |t|
    t.string "state"
    t.integer "merge_request_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "base_commit_sha"
    t.string "real_size"
    t.string "head_commit_sha"
    t.string "start_commit_sha"
    t.integer "commits_count"
    t.string "external_diff"
    t.integer "external_diff_store"
    t.boolean "stored_externally"
    t.index ["merge_request_id", "id"], name: "index_merge_request_diffs_on_merge_request_id_and_id", using: :btree
    t.index ["merge_request_id", "id"], name: "index_merge_request_diffs_on_merge_request_id_and_id_partial", where: "((NOT stored_externally) OR (stored_externally IS NULL))", using: :btree
  end

  create_table "merge_request_metrics", id: :serial, force: :cascade do |t|
    t.integer "merge_request_id", null: false
    t.datetime "latest_build_started_at"
    t.datetime "latest_build_finished_at"
    t.datetime "first_deployed_to_production_at"
    t.datetime "merged_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "pipeline_id"
    t.integer "merged_by_id"
    t.integer "latest_closed_by_id"
    t.datetime_with_timezone "latest_closed_at"
    t.index ["first_deployed_to_production_at"], name: "index_merge_request_metrics_on_first_deployed_to_production_at", using: :btree
    t.index ["latest_closed_at"], name: "index_merge_request_metrics_on_latest_closed_at", where: "(latest_closed_at IS NOT NULL)", using: :btree
    t.index ["latest_closed_by_id"], name: "index_merge_request_metrics_on_latest_closed_by_id", using: :btree
    t.index ["merge_request_id", "merged_at"], name: "index_merge_request_metrics_on_merge_request_id_and_merged_at", where: "(merged_at IS NOT NULL)", using: :btree
    t.index ["merge_request_id"], name: "index_merge_request_metrics", using: :btree
    t.index ["merged_by_id"], name: "index_merge_request_metrics_on_merged_by_id", using: :btree
    t.index ["pipeline_id"], name: "index_merge_request_metrics_on_pipeline_id", using: :btree
  end

  create_table "merge_requests", id: :serial, force: :cascade do |t|
    t.string "target_branch", null: false
    t.string "source_branch", null: false
    t.integer "source_project_id"
    t.integer "author_id"
    t.integer "assignee_id"
    t.string "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "milestone_id"
    t.string "state", default: "opened", null: false
    t.string "merge_status", default: "unchecked", null: false
    t.integer "target_project_id", null: false
    t.integer "iid"
    t.text "description"
    t.integer "updated_by_id"
    t.text "merge_error"
    t.text "merge_params"
    t.boolean "merge_when_pipeline_succeeds", default: false, null: false
    t.integer "merge_user_id"
    t.string "merge_commit_sha"
    t.string "in_progress_merge_commit_sha"
    t.integer "lock_version"
    t.text "title_html"
    t.text "description_html"
    t.integer "time_estimate"
    t.integer "cached_markdown_version"
    t.datetime "last_edited_at"
    t.integer "last_edited_by_id"
    t.integer "head_pipeline_id"
    t.string "merge_jid"
    t.boolean "discussion_locked"
    t.integer "latest_merge_request_diff_id"
    t.string "rebase_commit_sha"
    t.boolean "squash", default: false, null: false
    t.boolean "allow_maintainer_to_push"
    t.integer "state_id", limit: 2
    t.index ["assignee_id"], name: "index_merge_requests_on_assignee_id", using: :btree
    t.index ["author_id"], name: "index_merge_requests_on_author_id", using: :btree
    t.index ["created_at"], name: "index_merge_requests_on_created_at", using: :btree
    t.index ["description"], name: "index_merge_requests_on_description_trigram", using: :gin, opclasses: {"description"=>"gin_trgm_ops"}
    t.index ["head_pipeline_id"], name: "index_merge_requests_on_head_pipeline_id", using: :btree
    t.index ["id", "merge_jid"], name: "index_merge_requests_on_id_and_merge_jid", where: "((merge_jid IS NOT NULL) AND ((state)::text = 'locked'::text))", using: :btree
    t.index ["latest_merge_request_diff_id"], name: "index_merge_requests_on_latest_merge_request_diff_id", using: :btree
    t.index ["merge_user_id"], name: "index_merge_requests_on_merge_user_id", where: "(merge_user_id IS NOT NULL)", using: :btree
    t.index ["milestone_id"], name: "index_merge_requests_on_milestone_id", using: :btree
    t.index ["source_branch"], name: "index_merge_requests_on_source_branch", using: :btree
    t.index ["source_project_id", "source_branch"], name: "index_merge_requests_on_source_project_and_branch_state_opened", where: "((state)::text = 'opened'::text)", using: :btree
    t.index ["source_project_id", "source_branch"], name: "index_merge_requests_on_source_project_id_and_source_branch", using: :btree
    t.index ["state", "merge_status"], name: "index_merge_requests_on_state_and_merge_status", where: "(((state)::text = 'opened'::text) AND ((merge_status)::text = 'can_be_merged'::text))", using: :btree
    t.index ["target_branch"], name: "index_merge_requests_on_target_branch", using: :btree
    t.index ["target_project_id", "iid"], name: "index_merge_requests_on_target_project_id_and_iid", unique: true, using: :btree
    t.index ["target_project_id", "iid"], name: "index_merge_requests_on_target_project_id_and_iid_opened", where: "((state)::text = 'opened'::text)", using: :btree
    t.index ["target_project_id", "merge_commit_sha", "id"], name: "index_merge_requests_on_tp_id_and_merge_commit_sha_and_id", using: :btree
    t.index ["title"], name: "index_merge_requests_on_title", using: :btree
    t.index ["title"], name: "index_merge_requests_on_title_trigram", using: :gin, opclasses: {"title"=>"gin_trgm_ops"}
    t.index ["updated_by_id"], name: "index_merge_requests_on_updated_by_id", where: "(updated_by_id IS NOT NULL)", using: :btree
  end

  create_table "merge_requests_closing_issues", id: :serial, force: :cascade do |t|
    t.integer "merge_request_id", null: false
    t.integer "issue_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["issue_id"], name: "index_merge_requests_closing_issues_on_issue_id", using: :btree
    t.index ["merge_request_id"], name: "index_merge_requests_closing_issues_on_merge_request_id", using: :btree
  end

  create_table "merge_trains", force: :cascade do |t|
    t.integer "merge_request_id", null: false
    t.integer "user_id", null: false
    t.integer "pipeline_id"
    t.datetime_with_timezone "created_at", null: false
    t.datetime_with_timezone "updated_at", null: false
    t.index ["merge_request_id"], name: "index_merge_trains_on_merge_request_id", unique: true, using: :btree
    t.index ["pipeline_id"], name: "index_merge_trains_on_pipeline_id", using: :btree
    t.index ["user_id"], name: "index_merge_trains_on_user_id", using: :btree
  end

  create_table "milestones", id: :serial, force: :cascade do |t|
    t.string "title", null: false
    t.integer "project_id"
    t.text "description"
    t.date "due_date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "state"
    t.integer "iid"
    t.text "title_html"
    t.text "description_html"
    t.date "start_date"
    t.integer "cached_markdown_version"
    t.integer "group_id"
    t.index ["description"], name: "index_milestones_on_description_trigram", using: :gin, opclasses: {"description"=>"gin_trgm_ops"}
    t.index ["due_date"], name: "index_milestones_on_due_date", using: :btree
    t.index ["group_id"], name: "index_milestones_on_group_id", using: :btree
    t.index ["project_id", "iid"], name: "index_milestones_on_project_id_and_iid", unique: true, using: :btree
    t.index ["title"], name: "index_milestones_on_title", using: :btree
    t.index ["title"], name: "index_milestones_on_title_trigram", using: :gin, opclasses: {"title"=>"gin_trgm_ops"}
  end

  create_table "namespaces", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.string "path", null: false
    t.integer "owner_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "type"
    t.string "description", default: "", null: false
    t.string "avatar"
    t.boolean "share_with_group_lock", default: false
    t.integer "visibility_level", default: 20, null: false
    t.boolean "request_access_enabled", default: false, null: false
    t.text "description_html"
    t.boolean "lfs_enabled"
    t.integer "parent_id"
    t.boolean "require_two_factor_authentication", default: false, null: false
    t.integer "two_factor_grace_period", default: 48, null: false
    t.integer "cached_markdown_version"
    t.string "runners_token"
    t.string "runners_token_encrypted"
    t.integer "project_creation_level"
    t.boolean "auto_devops_enabled"
    t.index ["created_at"], name: "index_namespaces_on_created_at", using: :btree
    t.index ["name", "parent_id"], name: "index_namespaces_on_name_and_parent_id", unique: true, using: :btree
    t.index ["name"], name: "index_namespaces_on_name_trigram", using: :gin, opclasses: {"name"=>"gin_trgm_ops"}
    t.index ["owner_id"], name: "index_namespaces_on_owner_id", using: :btree
    t.index ["parent_id", "id"], name: "index_namespaces_on_parent_id_and_id", unique: true, using: :btree
    t.index ["path"], name: "index_namespaces_on_path", using: :btree
    t.index ["path"], name: "index_namespaces_on_path_trigram", using: :gin, opclasses: {"path"=>"gin_trgm_ops"}
    t.index ["require_two_factor_authentication"], name: "index_namespaces_on_require_two_factor_authentication", using: :btree
    t.index ["runners_token"], name: "index_namespaces_on_runners_token", unique: true, using: :btree
    t.index ["runners_token_encrypted"], name: "index_namespaces_on_runners_token_encrypted", unique: true, using: :btree
    t.index ["type"], name: "index_namespaces_on_type", using: :btree
  end

  create_table "note_diff_files", id: :serial, force: :cascade do |t|
    t.integer "diff_note_id", null: false
    t.text "diff", null: false
    t.boolean "new_file", null: false
    t.boolean "renamed_file", null: false
    t.boolean "deleted_file", null: false
    t.string "a_mode", null: false
    t.string "b_mode", null: false
    t.text "new_path", null: false
    t.text "old_path", null: false
    t.index ["diff_note_id"], name: "index_note_diff_files_on_diff_note_id", unique: true, using: :btree
  end

  create_table "notes", id: :serial, force: :cascade do |t|
    t.text "note"
    t.string "noteable_type"
    t.integer "author_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "project_id"
    t.string "attachment"
    t.string "line_code"
    t.string "commit_id"
    t.integer "noteable_id"
    t.boolean "system", default: false, null: false
    t.text "st_diff"
    t.integer "updated_by_id"
    t.string "type"
    t.text "position"
    t.text "original_position"
    t.datetime "resolved_at"
    t.integer "resolved_by_id"
    t.string "discussion_id"
    t.text "note_html"
    t.integer "cached_markdown_version"
    t.text "change_position"
    t.boolean "resolved_by_push"
    t.index ["author_id"], name: "index_notes_on_author_id", using: :btree
    t.index ["commit_id"], name: "index_notes_on_commit_id", using: :btree
    t.index ["created_at"], name: "index_notes_on_created_at", using: :btree
    t.index ["discussion_id"], name: "index_notes_on_discussion_id", using: :btree
    t.index ["line_code"], name: "index_notes_on_line_code", using: :btree
    t.index ["note"], name: "index_notes_on_note_trigram", using: :gin, opclasses: {"note"=>"gin_trgm_ops"}
    t.index ["noteable_id", "noteable_type"], name: "index_notes_on_noteable_id_and_noteable_type", using: :btree
    t.index ["noteable_type"], name: "index_notes_on_noteable_type", using: :btree
    t.index ["project_id", "noteable_type"], name: "index_notes_on_project_id_and_noteable_type", using: :btree
  end

  create_table "notification_settings", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "source_id"
    t.string "source_type"
    t.integer "level", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "new_note"
    t.boolean "new_issue"
    t.boolean "reopen_issue"
    t.boolean "close_issue"
    t.boolean "reassign_issue"
    t.boolean "new_merge_request"
    t.boolean "reopen_merge_request"
    t.boolean "close_merge_request"
    t.boolean "reassign_merge_request"
    t.boolean "merge_merge_request"
    t.boolean "failed_pipeline"
    t.boolean "success_pipeline"
    t.boolean "push_to_merge_request"
    t.boolean "issue_due"
    t.string "notification_email"
    t.index ["source_id", "source_type"], name: "index_notification_settings_on_source_id_and_source_type", using: :btree
    t.index ["user_id", "source_id", "source_type"], name: "index_notifications_on_user_id_and_source_id_and_source_type", unique: true, using: :btree
    t.index ["user_id"], name: "index_notification_settings_on_user_id", using: :btree
  end

  create_table "oauth_access_grants", id: :serial, force: :cascade do |t|
    t.integer "resource_owner_id", null: false
    t.integer "application_id", null: false
    t.string "token", null: false
    t.integer "expires_in", null: false
    t.text "redirect_uri", null: false
    t.datetime "created_at", null: false
    t.datetime "revoked_at"
    t.string "scopes"
    t.index ["token"], name: "index_oauth_access_grants_on_token", unique: true, using: :btree
  end

  create_table "oauth_access_tokens", id: :serial, force: :cascade do |t|
    t.integer "resource_owner_id"
    t.integer "application_id"
    t.string "token", null: false
    t.string "refresh_token"
    t.integer "expires_in"
    t.datetime "revoked_at"
    t.datetime "created_at", null: false
    t.string "scopes"
    t.index ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true, using: :btree
    t.index ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id", using: :btree
    t.index ["token"], name: "index_oauth_access_tokens_on_token", unique: true, using: :btree
  end

  create_table "oauth_applications", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.string "uid", null: false
    t.string "secret", null: false
    t.text "redirect_uri", null: false
    t.string "scopes", default: "", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "owner_id"
    t.string "owner_type"
    t.boolean "trusted", default: false, null: false
    t.index ["owner_id", "owner_type"], name: "index_oauth_applications_on_owner_id_and_owner_type", using: :btree
    t.index ["uid"], name: "index_oauth_applications_on_uid", unique: true, using: :btree
  end

  create_table "oauth_openid_requests", id: :serial, force: :cascade do |t|
    t.integer "access_grant_id", null: false
    t.string "nonce", null: false
    t.index ["access_grant_id"], name: "index_oauth_openid_requests_on_access_grant_id", using: :btree
  end

  create_table "pages_domain_acme_orders", force: :cascade do |t|
    t.integer "pages_domain_id", null: false
    t.datetime_with_timezone "expires_at", null: false
    t.datetime_with_timezone "created_at", null: false
    t.datetime_with_timezone "updated_at", null: false
    t.string "url", null: false
    t.string "challenge_token", null: false
    t.text "challenge_file_content", null: false
    t.text "encrypted_private_key", null: false
    t.text "encrypted_private_key_iv", null: false
    t.index ["challenge_token"], name: "index_pages_domain_acme_orders_on_challenge_token", using: :btree
    t.index ["pages_domain_id"], name: "index_pages_domain_acme_orders_on_pages_domain_id", using: :btree
  end

  create_table "pages_domains", id: :serial, force: :cascade do |t|
    t.integer "project_id"
    t.text "certificate"
    t.text "encrypted_key"
    t.string "encrypted_key_iv"
    t.string "encrypted_key_salt"
    t.string "domain"
    t.datetime_with_timezone "verified_at"
    t.string "verification_code", null: false
    t.datetime_with_timezone "enabled_until"
    t.datetime_with_timezone "remove_at"
    t.boolean "auto_ssl_enabled", default: false, null: false
    t.datetime_with_timezone "certificate_valid_not_before"
    t.datetime_with_timezone "certificate_valid_not_after"
    t.index ["domain"], name: "index_pages_domains_on_domain", unique: true, using: :btree
    t.index ["project_id", "enabled_until"], name: "index_pages_domains_on_project_id_and_enabled_until", using: :btree
    t.index ["project_id"], name: "index_pages_domains_on_project_id", using: :btree
    t.index ["remove_at"], name: "index_pages_domains_on_remove_at", using: :btree
    t.index ["verified_at", "enabled_until"], name: "index_pages_domains_on_verified_at_and_enabled_until", using: :btree
    t.index ["verified_at"], name: "index_pages_domains_on_verified_at", using: :btree
  end

  create_table "personal_access_tokens", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "name", null: false
    t.boolean "revoked", default: false
    t.date "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "scopes", default: "--- []\n", null: false
    t.boolean "impersonation", default: false, null: false
    t.string "token_digest"
    t.index ["token_digest"], name: "index_personal_access_tokens_on_token_digest", unique: true, using: :btree
    t.index ["user_id"], name: "index_personal_access_tokens_on_user_id", using: :btree
  end

  create_table "pool_repositories", force: :cascade do |t|
    t.integer "shard_id", null: false
    t.string "disk_path"
    t.string "state"
    t.integer "source_project_id"
    t.index ["disk_path"], name: "index_pool_repositories_on_disk_path", unique: true, using: :btree
    t.index ["shard_id"], name: "index_pool_repositories_on_shard_id", using: :btree
    t.index ["source_project_id"], name: "index_pool_repositories_on_source_project_id", unique: true, using: :btree
  end

  create_table "programming_languages", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.string "color", null: false
    t.datetime_with_timezone "created_at", null: false
    t.index ["name"], name: "index_programming_languages_on_name", unique: true, using: :btree
  end

  create_table "project_authorizations", id: false, force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "project_id", null: false
    t.integer "access_level", null: false
    t.index ["project_id"], name: "index_project_authorizations_on_project_id", using: :btree
    t.index ["user_id", "project_id", "access_level"], name: "index_project_authorizations_on_user_id_project_id_access_level", unique: true, using: :btree
  end

  create_table "project_auto_devops", id: :serial, force: :cascade do |t|
    t.integer "project_id", null: false
    t.datetime_with_timezone "created_at", null: false
    t.datetime_with_timezone "updated_at", null: false
    t.boolean "enabled"
    t.integer "deploy_strategy", default: 0, null: false
    t.index ["project_id"], name: "index_project_auto_devops_on_project_id", unique: true, using: :btree
  end

  create_table "project_ci_cd_settings", id: :serial, force: :cascade do |t|
    t.integer "project_id", null: false
    t.boolean "group_runners_enabled", default: true, null: false
    t.boolean "merge_pipelines_enabled"
    t.boolean "merge_trains_enabled", default: false, null: false
    t.integer "default_git_depth"
    t.index ["project_id"], name: "index_project_ci_cd_settings_on_project_id", unique: true, using: :btree
  end

  create_table "project_custom_attributes", id: :serial, force: :cascade do |t|
    t.datetime_with_timezone "created_at", null: false
    t.datetime_with_timezone "updated_at", null: false
    t.integer "project_id", null: false
    t.string "key", null: false
    t.string "value", null: false
    t.index ["key", "value"], name: "index_project_custom_attributes_on_key_and_value", using: :btree
    t.index ["project_id", "key"], name: "index_project_custom_attributes_on_project_id_and_key", unique: true, using: :btree
  end

  create_table "project_daily_statistics", force: :cascade do |t|
    t.integer "project_id", null: false
    t.integer "fetch_count", null: false
    t.date "date"
    t.index ["project_id", "date"], name: "index_project_daily_statistics_on_project_id_and_date", unique: true, order: { date: :desc }, using: :btree
  end

  create_table "project_deploy_tokens", id: :serial, force: :cascade do |t|
    t.integer "project_id", null: false
    t.integer "deploy_token_id", null: false
    t.datetime_with_timezone "created_at", null: false
    t.index ["deploy_token_id"], name: "index_project_deploy_tokens_on_deploy_token_id", using: :btree
    t.index ["project_id", "deploy_token_id"], name: "index_project_deploy_tokens_on_project_id_and_deploy_token_id", unique: true, using: :btree
  end

  create_table "project_error_tracking_settings", primary_key: "project_id", id: :integer, default: nil, force: :cascade do |t|
    t.boolean "enabled", default: false, null: false
    t.string "api_url"
    t.string "encrypted_token"
    t.string "encrypted_token_iv"
    t.string "project_name"
    t.string "organization_name"
  end

  create_table "project_features", id: :serial, force: :cascade do |t|
    t.integer "project_id", null: false
    t.integer "merge_requests_access_level"
    t.integer "issues_access_level"
    t.integer "wiki_access_level"
    t.integer "snippets_access_level", default: 20, null: false
    t.integer "builds_access_level"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "repository_access_level", default: 20, null: false
    t.integer "pages_access_level", default: 20, null: false
    t.index ["project_id"], name: "index_project_features_on_project_id", unique: true, using: :btree
  end

  create_table "project_group_links", id: :serial, force: :cascade do |t|
    t.integer "project_id", null: false
    t.integer "group_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "group_access", default: 30, null: false
    t.date "expires_at"
    t.index ["group_id"], name: "index_project_group_links_on_group_id", using: :btree
    t.index ["project_id"], name: "index_project_group_links_on_project_id", using: :btree
  end

  create_table "project_import_data", id: :serial, force: :cascade do |t|
    t.integer "project_id"
    t.text "data"
    t.text "encrypted_credentials"
    t.string "encrypted_credentials_iv"
    t.string "encrypted_credentials_salt"
    t.index ["project_id"], name: "index_project_import_data_on_project_id", using: :btree
  end

  create_table "project_metrics_settings", primary_key: "project_id", id: :integer, default: nil, force: :cascade do |t|
    t.string "external_dashboard_url", null: false
  end

  create_table "project_mirror_data", id: :serial, force: :cascade do |t|
    t.integer "project_id", null: false
    t.string "status"
    t.string "jid"
    t.text "last_error"
    t.index ["jid"], name: "index_project_mirror_data_on_jid", using: :btree
    t.index ["project_id"], name: "index_project_mirror_data_on_project_id", unique: true, using: :btree
    t.index ["status"], name: "index_project_mirror_data_on_status", using: :btree
  end

  create_table "project_repositories", force: :cascade do |t|
    t.integer "shard_id", null: false
    t.string "disk_path", null: false
    t.integer "project_id", null: false
    t.index ["disk_path"], name: "index_project_repositories_on_disk_path", unique: true, using: :btree
    t.index ["project_id"], name: "index_project_repositories_on_project_id", unique: true, using: :btree
    t.index ["shard_id"], name: "index_project_repositories_on_shard_id", using: :btree
  end

  create_table "project_statistics", id: :serial, force: :cascade do |t|
    t.integer "project_id", null: false
    t.integer "namespace_id", null: false
    t.bigint "commit_count", default: 0, null: false
    t.bigint "storage_size", default: 0, null: false
    t.bigint "repository_size", default: 0, null: false
    t.bigint "lfs_objects_size", default: 0, null: false
    t.bigint "build_artifacts_size", default: 0, null: false
    t.bigint "packages_size", default: 0, null: false
    t.bigint "wiki_size"
    t.index ["namespace_id"], name: "index_project_statistics_on_namespace_id", using: :btree
    t.index ["project_id"], name: "index_project_statistics_on_project_id", unique: true, using: :btree
  end

  create_table "projects", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "path"
    t.text "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "creator_id"
    t.integer "namespace_id", null: false
    t.datetime "last_activity_at"
    t.string "import_url"
    t.integer "visibility_level", default: 0, null: false
    t.boolean "archived", default: false, null: false
    t.string "avatar"
    t.string "import_status"
    t.integer "star_count", default: 0, null: false
    t.string "import_type"
    t.string "import_source"
    t.text "import_error"
    t.boolean "shared_runners_enabled", default: true, null: false
    t.string "runners_token"
    t.string "build_coverage_regex"
    t.boolean "build_allow_git_fetch", default: true, null: false
    t.integer "build_timeout", default: 3600, null: false
    t.boolean "pending_delete", default: false
    t.boolean "public_builds", default: true, null: false
    t.boolean "last_repository_check_failed"
    t.datetime "last_repository_check_at"
    t.boolean "container_registry_enabled"
    t.boolean "only_allow_merge_if_pipeline_succeeds", default: false, null: false
    t.boolean "has_external_issue_tracker"
    t.string "repository_storage", default: "default", null: false
    t.boolean "request_access_enabled", default: false, null: false
    t.boolean "has_external_wiki"
    t.string "ci_config_path"
    t.boolean "lfs_enabled"
    t.text "description_html"
    t.boolean "only_allow_merge_if_all_discussions_are_resolved"
    t.boolean "printing_merge_request_link_enabled", default: true, null: false
    t.integer "auto_cancel_pending_pipelines", default: 1, null: false
    t.string "import_jid"
    t.integer "cached_markdown_version"
    t.text "delete_error"
    t.datetime "last_repository_updated_at"
    t.integer "storage_version", limit: 2
    t.boolean "resolve_outdated_diff_discussions"
    t.boolean "repository_read_only"
    t.boolean "merge_requests_ff_only_enabled", default: false
    t.boolean "merge_requests_rebase_enabled", default: false, null: false
    t.integer "jobs_cache_index"
    t.boolean "pages_https_only", default: true
    t.boolean "remote_mirror_available_overridden"
    t.bigint "pool_repository_id"
    t.string "runners_token_encrypted"
    t.string "bfg_object_map"
    t.boolean "detected_repository_languages"
    t.string "external_authorization_classification_label"
    t.index ["created_at"], name: "index_projects_on_created_at", using: :btree
    t.index ["creator_id"], name: "index_projects_on_creator_id", using: :btree
    t.index ["description"], name: "index_projects_on_description_trigram", using: :gin, opclasses: {"description"=>"gin_trgm_ops"}
    t.index ["id"], name: "index_projects_on_id_partial_for_visibility", unique: true, where: "(visibility_level = ANY (ARRAY[10, 20]))", using: :btree
    t.index ["last_activity_at"], name: "index_projects_on_last_activity_at", using: :btree
    t.index ["last_repository_check_at"], name: "index_projects_on_last_repository_check_at", where: "(last_repository_check_at IS NOT NULL)", using: :btree
    t.index ["last_repository_check_failed"], name: "index_projects_on_last_repository_check_failed", using: :btree
    t.index ["last_repository_updated_at"], name: "index_projects_on_last_repository_updated_at", using: :btree
    t.index ["name"], name: "index_projects_on_name_trigram", using: :gin, opclasses: {"name"=>"gin_trgm_ops"}
    t.index ["namespace_id"], name: "index_projects_on_namespace_id", using: :btree
    t.index ["path"], name: "index_projects_on_path", using: :btree
    t.index ["path"], name: "index_projects_on_path_trigram", using: :gin, opclasses: {"path"=>"gin_trgm_ops"}
    t.index ["pending_delete"], name: "index_projects_on_pending_delete", using: :btree
    t.index ["pool_repository_id"], name: "index_projects_on_pool_repository_id", where: "(pool_repository_id IS NOT NULL)", using: :btree
    t.index ["repository_storage", "created_at"], name: "idx_project_repository_check_partial", where: "(last_repository_check_at IS NULL)", using: :btree
    t.index ["repository_storage"], name: "index_projects_on_repository_storage", using: :btree
    t.index ["runners_token"], name: "index_projects_on_runners_token", using: :btree
    t.index ["runners_token_encrypted"], name: "index_projects_on_runners_token_encrypted", using: :btree
    t.index ["star_count"], name: "index_projects_on_star_count", using: :btree
    t.index ["visibility_level"], name: "index_projects_on_visibility_level", using: :btree
  end

  create_table "prometheus_metrics", id: :serial, force: :cascade do |t|
    t.integer "project_id"
    t.string "title", null: false
    t.string "query", null: false
    t.string "y_label"
    t.string "unit"
    t.string "legend"
    t.integer "group", null: false
    t.datetime_with_timezone "created_at", null: false
    t.datetime_with_timezone "updated_at", null: false
    t.boolean "common", default: false, null: false
    t.string "identifier"
    t.index ["common"], name: "index_prometheus_metrics_on_common", using: :btree
    t.index ["group"], name: "index_prometheus_metrics_on_group", using: :btree
    t.index ["identifier"], name: "index_prometheus_metrics_on_identifier", unique: true, using: :btree
    t.index ["project_id"], name: "index_prometheus_metrics_on_project_id", using: :btree
  end

  create_table "protected_branch_merge_access_levels", id: :serial, force: :cascade do |t|
    t.integer "protected_branch_id", null: false
    t.integer "access_level", default: 40, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["protected_branch_id"], name: "index_protected_branch_merge_access", using: :btree
  end

  create_table "protected_branch_push_access_levels", id: :serial, force: :cascade do |t|
    t.integer "protected_branch_id", null: false
    t.integer "access_level", default: 40, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["protected_branch_id"], name: "index_protected_branch_push_access", using: :btree
  end

  create_table "protected_branches", id: :serial, force: :cascade do |t|
    t.integer "project_id", null: false
    t.string "name", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["project_id"], name: "index_protected_branches_on_project_id", using: :btree
  end

  create_table "protected_tag_create_access_levels", id: :serial, force: :cascade do |t|
    t.integer "protected_tag_id", null: false
    t.integer "access_level", default: 40
    t.integer "user_id"
    t.integer "group_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id"], name: "index_protected_tag_create_access_levels_on_group_id", using: :btree
    t.index ["protected_tag_id"], name: "index_protected_tag_create_access", using: :btree
    t.index ["user_id"], name: "index_protected_tag_create_access_levels_on_user_id", using: :btree
  end

  create_table "protected_tags", id: :serial, force: :cascade do |t|
    t.integer "project_id", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id", "name"], name: "index_protected_tags_on_project_id_and_name", unique: true, using: :btree
    t.index ["project_id"], name: "index_protected_tags_on_project_id", using: :btree
  end

  create_table "push_event_payloads", id: false, force: :cascade do |t|
    t.bigint "commit_count", null: false
    t.integer "event_id", null: false
    t.integer "action", limit: 2, null: false
    t.integer "ref_type", limit: 2, null: false
    t.binary "commit_from"
    t.binary "commit_to"
    t.text "ref"
    t.string "commit_title", limit: 70
    t.index ["event_id"], name: "index_push_event_payloads_on_event_id", unique: true, using: :btree
  end

  create_table "redirect_routes", id: :serial, force: :cascade do |t|
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.string "path", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["path"], name: "index_redirect_routes_on_path", unique: true, using: :btree
    t.index ["source_type", "source_id"], name: "index_redirect_routes_on_source_type_and_source_id", using: :btree
  end

  create_table "release_links", force: :cascade do |t|
    t.integer "release_id", null: false
    t.string "url", null: false
    t.string "name", null: false
    t.datetime_with_timezone "created_at", null: false
    t.datetime_with_timezone "updated_at", null: false
    t.index ["release_id", "name"], name: "index_release_links_on_release_id_and_name", unique: true, using: :btree
    t.index ["release_id", "url"], name: "index_release_links_on_release_id_and_url", unique: true, using: :btree
  end

  create_table "releases", id: :serial, force: :cascade do |t|
    t.string "tag"
    t.text "description"
    t.integer "project_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "description_html"
    t.integer "cached_markdown_version"
    t.integer "author_id"
    t.string "name"
    t.string "sha"
    t.index ["author_id"], name: "index_releases_on_author_id", using: :btree
    t.index ["project_id", "tag"], name: "index_releases_on_project_id_and_tag", using: :btree
    t.index ["project_id"], name: "index_releases_on_project_id", using: :btree
  end

  create_table "remote_mirrors", id: :serial, force: :cascade do |t|
    t.integer "project_id"
    t.string "url"
    t.boolean "enabled", default: false
    t.string "update_status"
    t.datetime "last_update_at"
    t.datetime "last_successful_update_at"
    t.datetime "last_update_started_at"
    t.string "last_error"
    t.boolean "only_protected_branches", default: false, null: false
    t.string "remote_name"
    t.text "encrypted_credentials"
    t.string "encrypted_credentials_iv"
    t.string "encrypted_credentials_salt"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "error_notification_sent"
    t.index ["last_successful_update_at"], name: "index_remote_mirrors_on_last_successful_update_at", using: :btree
    t.index ["project_id"], name: "index_remote_mirrors_on_project_id", using: :btree
  end

  create_table "repository_languages", id: false, force: :cascade do |t|
    t.integer "project_id", null: false
    t.integer "programming_language_id", null: false
    t.float "share", null: false
    t.index ["project_id", "programming_language_id"], name: "index_repository_languages_on_project_and_languages_id", unique: true, using: :btree
  end

  create_table "resource_label_events", force: :cascade do |t|
    t.integer "action", null: false
    t.integer "issue_id"
    t.integer "merge_request_id"
    t.integer "label_id"
    t.integer "user_id"
    t.datetime_with_timezone "created_at", null: false
    t.integer "cached_markdown_version"
    t.text "reference"
    t.text "reference_html"
    t.index ["issue_id"], name: "index_resource_label_events_on_issue_id", using: :btree
    t.index ["label_id"], name: "index_resource_label_events_on_label_id", using: :btree
    t.index ["merge_request_id"], name: "index_resource_label_events_on_merge_request_id", using: :btree
    t.index ["user_id"], name: "index_resource_label_events_on_user_id", using: :btree
  end

  create_table "routes", id: :serial, force: :cascade do |t|
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.string "path", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "name"
    t.index ["path"], name: "index_routes_on_path", unique: true, using: :btree
    t.index ["path"], name: "index_routes_on_path_text_pattern_ops", using: :btree, opclasses: {"path"=>"varchar_pattern_ops"}
    t.index ["source_type", "source_id"], name: "index_routes_on_source_type_and_source_id", unique: true, using: :btree
  end

  create_table "sent_notifications", id: :serial, force: :cascade do |t|
    t.integer "project_id"
    t.integer "noteable_id"
    t.string "noteable_type"
    t.integer "recipient_id"
    t.string "commit_id"
    t.string "reply_key", null: false
    t.string "line_code"
    t.string "note_type"
    t.text "position"
    t.string "in_reply_to_discussion_id"
    t.index ["reply_key"], name: "index_sent_notifications_on_reply_key", unique: true, using: :btree
  end

  create_table "services", id: :serial, force: :cascade do |t|
    t.string "type"
    t.string "title"
    t.integer "project_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "active", default: false, null: false
    t.text "properties"
    t.boolean "template", default: false
    t.boolean "push_events", default: true
    t.boolean "issues_events", default: true
    t.boolean "merge_requests_events", default: true
    t.boolean "tag_push_events", default: true
    t.boolean "note_events", default: true, null: false
    t.string "category", default: "common", null: false
    t.boolean "default", default: false
    t.boolean "wiki_page_events", default: true
    t.boolean "pipeline_events", default: false, null: false
    t.boolean "confidential_issues_events", default: true, null: false
    t.boolean "commit_events", default: true, null: false
    t.boolean "job_events", default: false, null: false
    t.boolean "confidential_note_events", default: true
    t.boolean "deployment_events", default: false, null: false
    t.index ["project_id"], name: "index_services_on_project_id", using: :btree
    t.index ["template"], name: "index_services_on_template", using: :btree
    t.index ["type"], name: "index_services_on_type", using: :btree
  end

  create_table "shards", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.index ["name"], name: "index_shards_on_name", unique: true, using: :btree
  end

  create_table "snippets", id: :serial, force: :cascade do |t|
    t.string "title"
    t.text "content"
    t.integer "author_id", null: false
    t.integer "project_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "file_name"
    t.string "type"
    t.integer "visibility_level", default: 0, null: false
    t.text "title_html"
    t.text "content_html"
    t.integer "cached_markdown_version"
    t.text "description"
    t.text "description_html"
    t.index ["author_id"], name: "index_snippets_on_author_id", using: :btree
    t.index ["file_name"], name: "index_snippets_on_file_name_trigram", using: :gin, opclasses: {"file_name"=>"gin_trgm_ops"}
    t.index ["project_id"], name: "index_snippets_on_project_id", using: :btree
    t.index ["title"], name: "index_snippets_on_title_trigram", using: :gin, opclasses: {"title"=>"gin_trgm_ops"}
    t.index ["updated_at"], name: "index_snippets_on_updated_at", using: :btree
    t.index ["visibility_level"], name: "index_snippets_on_visibility_level", using: :btree
  end

  create_table "spam_logs", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.string "source_ip"
    t.string "user_agent"
    t.boolean "via_api"
    t.string "noteable_type"
    t.string "title"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "submitted_as_ham", default: false, null: false
    t.boolean "recaptcha_verified", default: false, null: false
  end

  create_table "subscriptions", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "subscribable_id"
    t.string "subscribable_type"
    t.boolean "subscribed"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "project_id"
    t.index ["project_id"], name: "index_subscriptions_on_project_id", using: :btree
    t.index ["subscribable_id", "subscribable_type", "user_id", "project_id"], name: "index_subscriptions_on_subscribable_and_user_id_and_project_id", unique: true, using: :btree
  end

  create_table "suggestions", force: :cascade do |t|
    t.integer "note_id", null: false
    t.integer "relative_order", limit: 2, null: false
    t.boolean "applied", default: false, null: false
    t.string "commit_id"
    t.text "from_content", null: false
    t.text "to_content", null: false
    t.integer "lines_above", default: 0, null: false
    t.integer "lines_below", default: 0, null: false
    t.boolean "outdated", default: false, null: false
    t.index ["note_id", "relative_order"], name: "index_suggestions_on_note_id_and_relative_order", unique: true, using: :btree
  end

  create_table "system_note_metadata", id: :serial, force: :cascade do |t|
    t.integer "note_id", null: false
    t.integer "commit_count"
    t.string "action"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["note_id"], name: "index_system_note_metadata_on_note_id", unique: true, using: :btree
  end

  create_table "taggings", id: :serial, force: :cascade do |t|
    t.integer "tag_id"
    t.integer "taggable_id"
    t.string "taggable_type"
    t.integer "tagger_id"
    t.string "tagger_type"
    t.string "context"
    t.datetime "created_at"
    t.index ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "taggings_idx", unique: true, using: :btree
    t.index ["tag_id"], name: "index_taggings_on_tag_id", using: :btree
    t.index ["taggable_id", "taggable_type", "context"], name: "index_taggings_on_taggable_id_and_taggable_type_and_context", using: :btree
    t.index ["taggable_id", "taggable_type"], name: "index_taggings_on_taggable_id_and_taggable_type", using: :btree
  end

  create_table "tags", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "taggings_count", default: 0
    t.index ["name"], name: "index_tags_on_name", unique: true, using: :btree
    t.index ["name"], name: "index_tags_on_name_trigram", using: :gin, opclasses: {"name"=>"gin_trgm_ops"}
  end

  create_table "term_agreements", id: :serial, force: :cascade do |t|
    t.integer "term_id", null: false
    t.integer "user_id", null: false
    t.boolean "accepted", default: false, null: false
    t.datetime_with_timezone "created_at", null: false
    t.datetime_with_timezone "updated_at", null: false
    t.index ["term_id"], name: "index_term_agreements_on_term_id", using: :btree
    t.index ["user_id", "term_id"], name: "term_agreements_unique_index", unique: true, using: :btree
    t.index ["user_id"], name: "index_term_agreements_on_user_id", using: :btree
  end

  create_table "timelogs", id: :serial, force: :cascade do |t|
    t.integer "time_spent", null: false
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "issue_id"
    t.integer "merge_request_id"
    t.datetime_with_timezone "spent_at"
    t.index ["issue_id"], name: "index_timelogs_on_issue_id", using: :btree
    t.index ["merge_request_id"], name: "index_timelogs_on_merge_request_id", using: :btree
    t.index ["user_id"], name: "index_timelogs_on_user_id", using: :btree
  end

  create_table "todos", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "project_id"
    t.integer "target_id"
    t.string "target_type", null: false
    t.integer "author_id", null: false
    t.integer "action", null: false
    t.string "state", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "note_id"
    t.string "commit_id"
    t.integer "group_id"
    t.index ["author_id"], name: "index_todos_on_author_id", using: :btree
    t.index ["commit_id"], name: "index_todos_on_commit_id", using: :btree
    t.index ["group_id"], name: "index_todos_on_group_id", using: :btree
    t.index ["note_id"], name: "index_todos_on_note_id", using: :btree
    t.index ["project_id"], name: "index_todos_on_project_id", using: :btree
    t.index ["target_type", "target_id"], name: "index_todos_on_target_type_and_target_id", using: :btree
    t.index ["user_id", "id"], name: "index_todos_on_user_id_and_id_done", where: "((state)::text = 'done'::text)", using: :btree
    t.index ["user_id", "id"], name: "index_todos_on_user_id_and_id_pending", where: "((state)::text = 'pending'::text)", using: :btree
    t.index ["user_id"], name: "index_todos_on_user_id", using: :btree
  end

  create_table "trending_projects", id: :serial, force: :cascade do |t|
    t.integer "project_id", null: false
    t.index ["project_id"], name: "index_trending_projects_on_project_id", unique: true, using: :btree
  end

  create_table "u2f_registrations", id: :serial, force: :cascade do |t|
    t.text "certificate"
    t.string "key_handle"
    t.string "public_key"
    t.integer "counter"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.index ["key_handle"], name: "index_u2f_registrations_on_key_handle", using: :btree
    t.index ["user_id"], name: "index_u2f_registrations_on_user_id", using: :btree
  end

  create_table "uploads", id: :serial, force: :cascade do |t|
    t.bigint "size", null: false
    t.string "path", limit: 511, null: false
    t.string "checksum", limit: 64
    t.integer "model_id"
    t.string "model_type"
    t.string "uploader", null: false
    t.datetime "created_at", null: false
    t.string "mount_point"
    t.string "secret"
    t.integer "store"
    t.index ["checksum"], name: "index_uploads_on_checksum", using: :btree
    t.index ["model_id", "model_type"], name: "index_uploads_on_model_id_and_model_type", using: :btree
    t.index ["store"], name: "index_uploads_on_store", using: :btree
    t.index ["uploader", "path"], name: "index_uploads_on_uploader_and_path", using: :btree
  end

  create_table "user_agent_details", id: :serial, force: :cascade do |t|
    t.string "user_agent", null: false
    t.string "ip_address", null: false
    t.integer "subject_id", null: false
    t.string "subject_type", null: false
    t.boolean "submitted", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["subject_id", "subject_type"], name: "index_user_agent_details_on_subject_id_and_subject_type", using: :btree
  end

  create_table "user_callouts", id: :serial, force: :cascade do |t|
    t.integer "feature_name", null: false
    t.integer "user_id", null: false
    t.index ["user_id", "feature_name"], name: "index_user_callouts_on_user_id_and_feature_name", unique: true, using: :btree
    t.index ["user_id"], name: "index_user_callouts_on_user_id", using: :btree
  end

  create_table "user_custom_attributes", id: :serial, force: :cascade do |t|
    t.datetime_with_timezone "created_at", null: false
    t.datetime_with_timezone "updated_at", null: false
    t.integer "user_id", null: false
    t.string "key", null: false
    t.string "value", null: false
    t.index ["key", "value"], name: "index_user_custom_attributes_on_key_and_value", using: :btree
    t.index ["user_id", "key"], name: "index_user_custom_attributes_on_user_id_and_key", unique: true, using: :btree
  end

  create_table "user_interacted_projects", id: false, force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "project_id", null: false
    t.index ["project_id", "user_id"], name: "index_user_interacted_projects_on_project_id_and_user_id", unique: true, using: :btree
    t.index ["user_id"], name: "index_user_interacted_projects_on_user_id", using: :btree
  end

  create_table "user_preferences", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "issue_notes_filter", limit: 2, default: 0, null: false
    t.integer "merge_request_notes_filter", limit: 2, default: 0, null: false
    t.datetime_with_timezone "created_at", null: false
    t.datetime_with_timezone "updated_at", null: false
    t.integer "first_day_of_week"
    t.string "issues_sort"
    t.string "merge_requests_sort"
    t.string "timezone"
    t.boolean "time_display_relative"
    t.boolean "time_format_in_24h"
    t.index ["user_id"], name: "index_user_preferences_on_user_id", unique: true, using: :btree
  end

  create_table "user_statuses", primary_key: "user_id", id: :serial, force: :cascade do |t|
    t.integer "cached_markdown_version"
    t.string "emoji", default: "speech_balloon", null: false
    t.string "message", limit: 100
    t.string "message_html"
    t.index ["user_id"], name: "index_user_statuses_on_user_id", using: :btree
  end

  create_table "user_synced_attributes_metadata", id: :serial, force: :cascade do |t|
    t.boolean "name_synced", default: false
    t.boolean "email_synced", default: false
    t.boolean "location_synced", default: false
    t.integer "user_id", null: false
    t.string "provider"
    t.index ["user_id"], name: "index_user_synced_attributes_metadata_on_user_id", unique: true, using: :btree
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "name"
    t.boolean "admin", default: false, null: false
    t.integer "projects_limit", null: false
    t.string "skype", default: "", null: false
    t.string "linkedin", default: "", null: false
    t.string "twitter", default: "", null: false
    t.string "bio"
    t.integer "failed_attempts", default: 0
    t.datetime "locked_at"
    t.string "username"
    t.boolean "can_create_group", default: true, null: false
    t.boolean "can_create_team", default: true, null: false
    t.string "state"
    t.integer "color_scheme_id", default: 1, null: false
    t.datetime "password_expires_at"
    t.integer "created_by_id"
    t.datetime "last_credential_check_at"
    t.string "avatar"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.boolean "hide_no_ssh_key", default: false
    t.string "website_url", default: "", null: false
    t.string "notification_email"
    t.boolean "hide_no_password", default: false
    t.boolean "password_automatically_set", default: false
    t.string "location"
    t.string "encrypted_otp_secret"
    t.string "encrypted_otp_secret_iv"
    t.string "encrypted_otp_secret_salt"
    t.boolean "otp_required_for_login", default: false, null: false
    t.text "otp_backup_codes"
    t.string "public_email", default: "", null: false
    t.integer "dashboard", default: 0
    t.integer "project_view", default: 0
    t.integer "consumed_timestep"
    t.integer "layout", default: 0
    t.boolean "hide_project_limit", default: false
    t.string "unlock_token"
    t.datetime "otp_grace_period_started_at"
    t.boolean "external", default: false
    t.string "incoming_email_token"
    t.string "organization"
    t.boolean "require_two_factor_authentication_from_group", default: false, null: false
    t.integer "two_factor_grace_period", default: 48, null: false
    t.boolean "ghost"
    t.date "last_activity_on"
    t.boolean "notified_of_own_activity"
    t.string "preferred_language"
    t.integer "theme_id", limit: 2
    t.integer "accepted_term_id"
    t.string "feed_token"
    t.boolean "private_profile"
    t.boolean "include_private_contributions"
    t.string "commit_email"
    t.index ["accepted_term_id"], name: "index_users_on_accepted_term_id", using: :btree
    t.index ["admin"], name: "index_users_on_admin", using: :btree
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true, using: :btree
    t.index ["created_at"], name: "index_users_on_created_at", using: :btree
    t.index ["email"], name: "index_users_on_email", unique: true, using: :btree
    t.index ["email"], name: "index_users_on_email_trigram", using: :gin, opclasses: {"email"=>"gin_trgm_ops"}
    t.index ["feed_token"], name: "index_users_on_feed_token", using: :btree
    t.index ["ghost"], name: "index_users_on_ghost", using: :btree
    t.index ["incoming_email_token"], name: "index_users_on_incoming_email_token", using: :btree
    t.index ["name"], name: "index_users_on_name", using: :btree
    t.index ["name"], name: "index_users_on_name_trigram", using: :gin, opclasses: {"name"=>"gin_trgm_ops"}
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
    t.index ["state"], name: "index_users_on_state", using: :btree
    t.index ["username"], name: "index_users_on_username", using: :btree
    t.index ["username"], name: "index_users_on_username_trigram", using: :gin, opclasses: {"username"=>"gin_trgm_ops"}
  end

  create_table "users_star_projects", id: :serial, force: :cascade do |t|
    t.integer "project_id", null: false
    t.integer "user_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["project_id"], name: "index_users_star_projects_on_project_id", using: :btree
    t.index ["user_id", "project_id"], name: "index_users_star_projects_on_user_id_and_project_id", unique: true, using: :btree
  end

  create_table "web_hook_logs", id: :serial, force: :cascade do |t|
    t.integer "web_hook_id", null: false
    t.string "trigger"
    t.string "url"
    t.text "request_headers"
    t.text "request_data"
    t.text "response_headers"
    t.text "response_body"
    t.string "response_status"
    t.float "execution_duration"
    t.string "internal_error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at", "web_hook_id"], name: "index_web_hook_logs_on_created_at_and_web_hook_id", using: :btree
    t.index ["web_hook_id"], name: "index_web_hook_logs_on_web_hook_id", using: :btree
  end

  create_table "web_hooks", id: :serial, force: :cascade do |t|
    t.integer "project_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "type", default: "ProjectHook"
    t.integer "service_id"
    t.boolean "push_events", default: true, null: false
    t.boolean "issues_events", default: false, null: false
    t.boolean "merge_requests_events", default: false, null: false
    t.boolean "tag_push_events", default: false
    t.boolean "note_events", default: false, null: false
    t.boolean "enable_ssl_verification", default: true
    t.boolean "wiki_page_events", default: false, null: false
    t.boolean "pipeline_events", default: false, null: false
    t.boolean "confidential_issues_events", default: false, null: false
    t.boolean "repository_update_events", default: false, null: false
    t.boolean "job_events", default: false, null: false
    t.boolean "confidential_note_events"
    t.text "push_events_branch_filter"
    t.string "encrypted_token"
    t.string "encrypted_token_iv"
    t.string "encrypted_url"
    t.string "encrypted_url_iv"
    t.index ["project_id"], name: "index_web_hooks_on_project_id", using: :btree
    t.index ["type"], name: "index_web_hooks_on_type", using: :btree
  end

  add_foreign_key "application_settings", "users", column: "usage_stats_set_by_user_id", name: "fk_964370041d", on_delete: :nullify
  add_foreign_key "badges", "namespaces", column: "group_id", on_delete: :cascade
  add_foreign_key "badges", "projects", on_delete: :cascade
  add_foreign_key "board_group_recent_visits", "boards", on_delete: :cascade
  add_foreign_key "board_group_recent_visits", "namespaces", column: "group_id", on_delete: :cascade
  add_foreign_key "board_group_recent_visits", "users", on_delete: :cascade
  add_foreign_key "board_project_recent_visits", "boards", on_delete: :cascade
  add_foreign_key "board_project_recent_visits", "projects", on_delete: :cascade
  add_foreign_key "board_project_recent_visits", "users", on_delete: :cascade
  add_foreign_key "boards", "namespaces", column: "group_id", on_delete: :cascade
  add_foreign_key "boards", "projects", name: "fk_f15266b5f9", on_delete: :cascade
  add_foreign_key "chat_teams", "namespaces", on_delete: :cascade
  add_foreign_key "ci_build_trace_chunks", "ci_builds", column: "build_id", on_delete: :cascade
  add_foreign_key "ci_build_trace_section_names", "projects", on_delete: :cascade
  add_foreign_key "ci_build_trace_sections", "ci_build_trace_section_names", column: "section_name_id", name: "fk_264e112c66", on_delete: :cascade
  add_foreign_key "ci_build_trace_sections", "ci_builds", column: "build_id", name: "fk_4ebe41f502", on_delete: :cascade
  add_foreign_key "ci_build_trace_sections", "projects", on_delete: :cascade
  add_foreign_key "ci_builds", "ci_pipelines", column: "auto_canceled_by_id", name: "fk_a2141b1522", on_delete: :nullify
  add_foreign_key "ci_builds", "ci_pipelines", column: "commit_id", name: "fk_d3130c9a7f", on_delete: :cascade
  add_foreign_key "ci_builds", "ci_stages", column: "stage_id", name: "fk_3a9eaa254d", on_delete: :cascade
  add_foreign_key "ci_builds", "projects", name: "fk_befce0568a", on_delete: :cascade
  add_foreign_key "ci_builds_metadata", "ci_builds", column: "build_id", on_delete: :cascade
  add_foreign_key "ci_builds_metadata", "projects", on_delete: :cascade
  add_foreign_key "ci_builds_runner_session", "ci_builds", column: "build_id", on_delete: :cascade
  add_foreign_key "ci_group_variables", "namespaces", column: "group_id", name: "fk_33ae4d58d8", on_delete: :cascade
  add_foreign_key "ci_job_artifacts", "ci_builds", column: "job_id", on_delete: :cascade
  add_foreign_key "ci_job_artifacts", "projects", on_delete: :cascade
  add_foreign_key "ci_pipeline_chat_data", "chat_names", on_delete: :cascade
  add_foreign_key "ci_pipeline_chat_data", "ci_pipelines", column: "pipeline_id", on_delete: :cascade
  add_foreign_key "ci_pipeline_schedule_variables", "ci_pipeline_schedules", column: "pipeline_schedule_id", name: "fk_41c35fda51", on_delete: :cascade
  add_foreign_key "ci_pipeline_schedules", "projects", name: "fk_8ead60fcc4", on_delete: :cascade
  add_foreign_key "ci_pipeline_schedules", "users", column: "owner_id", name: "fk_9ea99f58d2", on_delete: :nullify
  add_foreign_key "ci_pipeline_variables", "ci_pipelines", column: "pipeline_id", name: "fk_f29c5f4380", on_delete: :cascade
  add_foreign_key "ci_pipelines", "ci_pipeline_schedules", column: "pipeline_schedule_id", name: "fk_3d34ab2e06", on_delete: :nullify
  add_foreign_key "ci_pipelines", "ci_pipelines", column: "auto_canceled_by_id", name: "fk_262d4c2d19", on_delete: :nullify
  add_foreign_key "ci_pipelines", "merge_requests", name: "fk_a23be95014", on_delete: :cascade
  add_foreign_key "ci_pipelines", "projects", name: "fk_86635dbd80", on_delete: :cascade
  add_foreign_key "ci_runner_namespaces", "ci_runners", column: "runner_id", on_delete: :cascade
  add_foreign_key "ci_runner_namespaces", "namespaces", on_delete: :cascade
  add_foreign_key "ci_runner_projects", "projects", name: "fk_4478a6f1e4", on_delete: :cascade
  add_foreign_key "ci_stages", "ci_pipelines", column: "pipeline_id", name: "fk_fb57e6cc56", on_delete: :cascade
  add_foreign_key "ci_stages", "projects", name: "fk_2360681d1d", on_delete: :cascade
  add_foreign_key "ci_trigger_requests", "ci_triggers", column: "trigger_id", name: "fk_b8ec8b7245", on_delete: :cascade
  add_foreign_key "ci_triggers", "projects", name: "fk_e3e63f966e", on_delete: :cascade
  add_foreign_key "ci_triggers", "users", column: "owner_id", name: "fk_e8e10d1964", on_delete: :cascade
  add_foreign_key "ci_variables", "projects", name: "fk_ada5eb64b3", on_delete: :cascade
  add_foreign_key "cluster_groups", "clusters", on_delete: :cascade
  add_foreign_key "cluster_groups", "namespaces", column: "group_id", on_delete: :cascade
  add_foreign_key "cluster_platforms_kubernetes", "clusters", on_delete: :cascade
  add_foreign_key "cluster_projects", "clusters", on_delete: :cascade
  add_foreign_key "cluster_projects", "projects", on_delete: :cascade
  add_foreign_key "cluster_providers_gcp", "clusters", on_delete: :cascade
  add_foreign_key "clusters", "users", on_delete: :nullify
  add_foreign_key "clusters_applications_cert_managers", "clusters", on_delete: :cascade
  add_foreign_key "clusters_applications_helm", "clusters", on_delete: :cascade
  add_foreign_key "clusters_applications_ingress", "clusters", name: "fk_753a7b41c1", on_delete: :cascade
  add_foreign_key "clusters_applications_jupyter", "clusters", on_delete: :cascade
  add_foreign_key "clusters_applications_jupyter", "oauth_applications", on_delete: :nullify
  add_foreign_key "clusters_applications_knative", "clusters", on_delete: :cascade
  add_foreign_key "clusters_applications_prometheus", "clusters", name: "fk_557e773639", on_delete: :cascade
  add_foreign_key "clusters_applications_runners", "ci_runners", column: "runner_id", name: "fk_02de2ded36", on_delete: :nullify
  add_foreign_key "clusters_applications_runners", "clusters", on_delete: :cascade
  add_foreign_key "clusters_kubernetes_namespaces", "cluster_projects", on_delete: :nullify
  add_foreign_key "clusters_kubernetes_namespaces", "clusters", on_delete: :cascade
  add_foreign_key "clusters_kubernetes_namespaces", "projects", on_delete: :nullify
  add_foreign_key "container_repositories", "projects"
  add_foreign_key "deploy_keys_projects", "projects", name: "fk_58a901ca7e", on_delete: :cascade
  add_foreign_key "deployments", "projects", name: "fk_b9a3851b82", on_delete: :cascade
  add_foreign_key "environments", "projects", name: "fk_d1c8c1da6a", on_delete: :cascade
  add_foreign_key "events", "projects", on_delete: :cascade
  add_foreign_key "events", "users", column: "author_id", name: "fk_edfd187b6f", on_delete: :cascade
  add_foreign_key "fork_network_members", "fork_networks", on_delete: :cascade
  add_foreign_key "fork_network_members", "projects", column: "forked_from_project_id", name: "fk_b01280dae4", on_delete: :nullify
  add_foreign_key "fork_network_members", "projects", on_delete: :cascade
  add_foreign_key "fork_networks", "projects", column: "root_project_id", name: "fk_e7b436b2b5", on_delete: :nullify
  add_foreign_key "forked_project_links", "projects", column: "forked_to_project_id", name: "fk_434510edb0", on_delete: :cascade
  add_foreign_key "gpg_key_subkeys", "gpg_keys", on_delete: :cascade
  add_foreign_key "gpg_keys", "users", on_delete: :cascade
  add_foreign_key "gpg_signatures", "gpg_key_subkeys", on_delete: :nullify
  add_foreign_key "gpg_signatures", "gpg_keys", on_delete: :nullify
  add_foreign_key "gpg_signatures", "projects", on_delete: :cascade
  add_foreign_key "group_custom_attributes", "namespaces", column: "group_id", on_delete: :cascade
  add_foreign_key "import_export_uploads", "projects", on_delete: :cascade
  add_foreign_key "internal_ids", "namespaces", name: "fk_162941d509", on_delete: :cascade
  add_foreign_key "internal_ids", "projects", on_delete: :cascade
  add_foreign_key "issue_assignees", "issues", name: "fk_b7d881734a", on_delete: :cascade
  add_foreign_key "issue_assignees", "users", name: "fk_5e0c8d9154", on_delete: :cascade
  add_foreign_key "issue_metrics", "issues", on_delete: :cascade
  add_foreign_key "issues", "issues", column: "moved_to_id", name: "fk_a194299be1", on_delete: :nullify
  add_foreign_key "issues", "milestones", name: "fk_96b1dd429c", on_delete: :nullify
  add_foreign_key "issues", "projects", name: "fk_899c8f3231", on_delete: :cascade
  add_foreign_key "issues", "users", column: "author_id", name: "fk_05f1e72feb", on_delete: :nullify
  add_foreign_key "issues", "users", column: "closed_by_id", name: "fk_c63cbf6c25", on_delete: :nullify
  add_foreign_key "issues", "users", column: "updated_by_id", name: "fk_ffed080f01", on_delete: :nullify
  add_foreign_key "label_links", "labels", name: "fk_d97dd08678", on_delete: :cascade
  add_foreign_key "label_priorities", "labels", on_delete: :cascade
  add_foreign_key "label_priorities", "projects", on_delete: :cascade
  add_foreign_key "labels", "namespaces", column: "group_id", on_delete: :cascade
  add_foreign_key "labels", "projects", name: "fk_7de4989a69", on_delete: :cascade
  add_foreign_key "lfs_file_locks", "projects", on_delete: :cascade
  add_foreign_key "lfs_file_locks", "users", on_delete: :cascade
  add_foreign_key "lists", "boards", name: "fk_0d3f677137", on_delete: :cascade
  add_foreign_key "lists", "labels", name: "fk_7a5553d60f", on_delete: :cascade
  add_foreign_key "members", "users", name: "fk_2e88fb7ce9", on_delete: :cascade
  add_foreign_key "merge_request_assignees", "merge_requests", on_delete: :cascade
  add_foreign_key "merge_request_assignees", "users", on_delete: :cascade
  add_foreign_key "merge_request_blocks", "merge_requests", column: "blocked_merge_request_id", on_delete: :cascade
  add_foreign_key "merge_request_blocks", "merge_requests", column: "blocking_merge_request_id", on_delete: :cascade
  add_foreign_key "merge_request_diff_commits", "merge_request_diffs", on_delete: :cascade
  add_foreign_key "merge_request_diff_files", "merge_request_diffs", on_delete: :cascade
  add_foreign_key "merge_request_diffs", "merge_requests", name: "fk_8483f3258f", on_delete: :cascade
  add_foreign_key "merge_request_metrics", "ci_pipelines", column: "pipeline_id", on_delete: :cascade
  add_foreign_key "merge_request_metrics", "merge_requests", on_delete: :cascade
  add_foreign_key "merge_request_metrics", "users", column: "latest_closed_by_id", name: "fk_ae440388cc", on_delete: :nullify
  add_foreign_key "merge_request_metrics", "users", column: "merged_by_id", name: "fk_7f28d925f3", on_delete: :nullify
  add_foreign_key "merge_requests", "ci_pipelines", column: "head_pipeline_id", name: "fk_fd82eae0b9", on_delete: :nullify
  add_foreign_key "merge_requests", "merge_request_diffs", column: "latest_merge_request_diff_id", name: "fk_06067f5644", on_delete: :nullify
  add_foreign_key "merge_requests", "milestones", name: "fk_6a5165a692", on_delete: :nullify
  add_foreign_key "merge_requests", "projects", column: "source_project_id", name: "fk_3308fe130c", on_delete: :nullify
  add_foreign_key "merge_requests", "projects", column: "target_project_id", name: "fk_a6963e8447", on_delete: :cascade
  add_foreign_key "merge_requests", "users", column: "assignee_id", name: "fk_6149611a04", on_delete: :nullify
  add_foreign_key "merge_requests", "users", column: "author_id", name: "fk_e719a85f8a", on_delete: :nullify
  add_foreign_key "merge_requests", "users", column: "merge_user_id", name: "fk_ad525e1f87", on_delete: :nullify
  add_foreign_key "merge_requests", "users", column: "updated_by_id", name: "fk_641731faff", on_delete: :nullify
  add_foreign_key "merge_requests_closing_issues", "issues", on_delete: :cascade
  add_foreign_key "merge_requests_closing_issues", "merge_requests", on_delete: :cascade
  add_foreign_key "merge_trains", "ci_pipelines", column: "pipeline_id", on_delete: :nullify
  add_foreign_key "merge_trains", "merge_requests", on_delete: :cascade
  add_foreign_key "merge_trains", "users", on_delete: :cascade
  add_foreign_key "milestones", "namespaces", column: "group_id", name: "fk_95650a40d4", on_delete: :cascade
  add_foreign_key "milestones", "projects", name: "fk_9bd0a0c791", on_delete: :cascade
  add_foreign_key "note_diff_files", "notes", column: "diff_note_id", on_delete: :cascade
  add_foreign_key "notes", "projects", name: "fk_99e097b079", on_delete: :cascade
  add_foreign_key "notification_settings", "users", name: "fk_0c95e91db7", on_delete: :cascade
  add_foreign_key "oauth_openid_requests", "oauth_access_grants", column: "access_grant_id", name: "fk_oauth_openid_requests_oauth_access_grants_access_grant_id"
  add_foreign_key "pages_domain_acme_orders", "pages_domains", on_delete: :cascade
  add_foreign_key "pages_domains", "projects", name: "fk_ea2f6dfc6f", on_delete: :cascade
  add_foreign_key "personal_access_tokens", "users"
  add_foreign_key "pool_repositories", "projects", column: "source_project_id", on_delete: :nullify
  add_foreign_key "pool_repositories", "shards", on_delete: :restrict
  add_foreign_key "project_authorizations", "projects", on_delete: :cascade
  add_foreign_key "project_authorizations", "users", on_delete: :cascade
  add_foreign_key "project_auto_devops", "projects", on_delete: :cascade
  add_foreign_key "project_ci_cd_settings", "projects", name: "fk_24c15d2f2e", on_delete: :cascade
  add_foreign_key "project_custom_attributes", "projects", on_delete: :cascade
  add_foreign_key "project_daily_statistics", "projects", on_delete: :cascade
  add_foreign_key "project_deploy_tokens", "deploy_tokens", on_delete: :cascade
  add_foreign_key "project_deploy_tokens", "projects", on_delete: :cascade
  add_foreign_key "project_error_tracking_settings", "projects", on_delete: :cascade
  add_foreign_key "project_features", "projects", name: "fk_18513d9b92", on_delete: :cascade
  add_foreign_key "project_group_links", "projects", name: "fk_daa8cee94c", on_delete: :cascade
  add_foreign_key "project_import_data", "projects", name: "fk_ffb9ee3a10", on_delete: :cascade
  add_foreign_key "project_metrics_settings", "projects", on_delete: :cascade
  add_foreign_key "project_mirror_data", "projects", on_delete: :cascade
  add_foreign_key "project_repositories", "projects", on_delete: :cascade
  add_foreign_key "project_repositories", "shards", on_delete: :restrict
  add_foreign_key "project_statistics", "projects", on_delete: :cascade
  add_foreign_key "projects", "pool_repositories", name: "fk_6e5c14658a", on_delete: :nullify
  add_foreign_key "prometheus_metrics", "projects", on_delete: :cascade
  add_foreign_key "protected_branch_merge_access_levels", "protected_branches", name: "fk_8a3072ccb3", on_delete: :cascade
  add_foreign_key "protected_branch_push_access_levels", "protected_branches", name: "fk_9ffc86a3d9", on_delete: :cascade
  add_foreign_key "protected_branches", "projects", name: "fk_7a9c6d93e7", on_delete: :cascade
  add_foreign_key "protected_tag_create_access_levels", "namespaces", column: "group_id"
  add_foreign_key "protected_tag_create_access_levels", "protected_tags", name: "fk_f7dfda8c51", on_delete: :cascade
  add_foreign_key "protected_tag_create_access_levels", "users"
  add_foreign_key "protected_tags", "projects", name: "fk_8e4af87648", on_delete: :cascade
  add_foreign_key "push_event_payloads", "events", name: "fk_36c74129da", on_delete: :cascade
  add_foreign_key "release_links", "releases", on_delete: :cascade
  add_foreign_key "releases", "projects", name: "fk_47fe2a0596", on_delete: :cascade
  add_foreign_key "releases", "users", column: "author_id", name: "fk_8e4456f90f", on_delete: :nullify
  add_foreign_key "remote_mirrors", "projects", on_delete: :cascade
  add_foreign_key "repository_languages", "projects", on_delete: :cascade
  add_foreign_key "resource_label_events", "issues", on_delete: :cascade
  add_foreign_key "resource_label_events", "labels", on_delete: :nullify
  add_foreign_key "resource_label_events", "merge_requests", on_delete: :cascade
  add_foreign_key "resource_label_events", "users", on_delete: :nullify
  add_foreign_key "services", "projects", name: "fk_71cce407f9", on_delete: :cascade
  add_foreign_key "snippets", "projects", name: "fk_be41fd4bb7", on_delete: :cascade
  add_foreign_key "subscriptions", "projects", on_delete: :cascade
  add_foreign_key "suggestions", "notes", on_delete: :cascade
  add_foreign_key "system_note_metadata", "notes", name: "fk_d83a918cb1", on_delete: :cascade
  add_foreign_key "term_agreements", "application_setting_terms", column: "term_id"
  add_foreign_key "term_agreements", "users", on_delete: :cascade
  add_foreign_key "timelogs", "issues", name: "fk_timelogs_issues_issue_id", on_delete: :cascade
  add_foreign_key "timelogs", "merge_requests", name: "fk_timelogs_merge_requests_merge_request_id", on_delete: :cascade
  add_foreign_key "todos", "namespaces", column: "group_id", on_delete: :cascade
  add_foreign_key "todos", "notes", name: "fk_91d1f47b13", on_delete: :cascade
  add_foreign_key "todos", "projects", name: "fk_45054f9c45", on_delete: :cascade
  add_foreign_key "todos", "users", column: "author_id", name: "fk_ccf0373936", on_delete: :cascade
  add_foreign_key "todos", "users", name: "fk_d94154aa95", on_delete: :cascade
  add_foreign_key "trending_projects", "projects", on_delete: :cascade
  add_foreign_key "u2f_registrations", "users"
  add_foreign_key "user_callouts", "users", on_delete: :cascade
  add_foreign_key "user_custom_attributes", "users", on_delete: :cascade
  add_foreign_key "user_interacted_projects", "projects", name: "fk_722ceba4f7", on_delete: :cascade
  add_foreign_key "user_interacted_projects", "users", name: "fk_0894651f08", on_delete: :cascade
  add_foreign_key "user_preferences", "users", on_delete: :cascade
  add_foreign_key "user_statuses", "users", on_delete: :cascade
  add_foreign_key "user_synced_attributes_metadata", "users", on_delete: :cascade
  add_foreign_key "users", "application_setting_terms", column: "accepted_term_id", name: "fk_789cd90b35", on_delete: :cascade
  add_foreign_key "users_star_projects", "projects", name: "fk_22cd27ddfc", on_delete: :cascade
  add_foreign_key "web_hook_logs", "web_hooks", on_delete: :cascade
  add_foreign_key "web_hooks", "projects", name: "fk_0c8ca6d9d1", on_delete: :cascade
end
