# frozen_string_literal: true

module Gitlab
  module ApplicationRateLimiter
    module LabkitAdapter
      # Single source of truth for the keys this adapter handles, paired
      # with ee/lib/ee/gitlab/application_rate_limiter/labkit_adapter/
      # supported_rate_limits.rb (EE additions, prepended via prepend_mod).
      #
      # Per-entry conventions:
      #   limiter_name:    Redis namespace prefix for the labkit Limiter.
      #   rule_name:       descriptive label for the labkit Rule.
      #   characteristics: ordered list of identifier slots; AR-typed
      #                    names (see LabkitAdapter#ar_characteristic_types)
      #                    are populated by class-routing, primitives fill
      #                    the remainder positionally. Polymorphic
      #                    positions list every accepted slot; labkit's
      #                    '_unknown_' sentinel fills slots not in scope,
      #                    keeping Redis keys disjoint per real type.
      #   limit:           static threshold (Integer) or a zero-arity callable
      #                    resolved per check against application settings.
      #                    Mirrors the value previously held in
      #                    ApplicationRateLimiter.rate_limits[key][:threshold].
      #                    Omitted for entries whose threshold arrives per call
      #                    (see threshold_from_caller and cost_mode below).
      #   period:          window as an Integer (seconds), an ActiveSupport
      #                    duration, or a callable. Mirrors the previous
      #                    rate_limits[key][:interval]. Omitted for cost_mode
      #                    entries (the interval arrives per call).
      #   action:          forwarded to the labkit Rule; the adapter
      #                    returns labkit's boolean decision to the caller.
      #
      # limit/period are the migration of the legacy `rate_limits` hash into
      # this registry. While the rate_limiter_resolve_limits_from_registry
      # feature flag is disabled the adapter still resolves them from the
      # rate_limits hash; a parity spec asserts the two sources resolve to
      # identical values for every key.
      #
      # `web_hook_calls{,_low,_mid}` receive their threshold per call from
      # PlanLimits and so omit `limit:` (it resolves to 0, matching the legacy
      # hash, which carried no threshold for them); the adapter forwards the
      # caller's value via rule_context rather than treating it as an override.
      module SupportedRateLimits
        def self.all
          @all ||= entries.freeze
        end

        def self.entries # rubocop:disable Metrics/AbcSize -- static registry of rate-limit definitions
          {
            ai_action: {
              limiter_name: 'applimiter_ai_action',
              rule_name: 'limit_ai_actions_by_user',
              characteristics: %i[user],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.ai_action_api_rate_limit },
              period: 8.hours,
              action: :block
            },
            auto_rollback_deployment: {
              limiter_name: 'applimiter_auto_rollback_deployment',
              rule_name: 'limit_auto_rollbacks_by_environment',
              characteristics: %i[environment],
              limit: 1,
              period: 3.minutes,
              action: :block
            },
            autocomplete_users: {
              limiter_name: 'applimiter_autocomplete_users',
              rule_name: 'limit_user_autocompletes_by_user',
              characteristics: %i[user],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.autocomplete_users_limit },
              period: 1.minute,
              action: :block
            },
            autocomplete_users_unauthenticated: {
              limiter_name: 'applimiter_autocomplete_users_unauthenticated',
              rule_name: 'limit_user_autocompletes_by_ip',
              characteristics: %i[ip],
              limit: -> {
                Gitlab::CurrentSettings.current_application_settings.autocomplete_users_unauthenticated_limit
              },
              period: 1.minute,
              action: :block
            },
            bitbucket_server_import: {
              limiter_name: 'applimiter_bitbucket_server_import',
              rule_name: 'limit_bitbucket_server_imports_by_user',
              characteristics: %i[user],
              limit: 6,
              period: 1.minute,
              action: :block
            },
            bulk_delete_todos: {
              limiter_name: 'applimiter_bulk_delete_todos',
              rule_name: 'limit_bulk_todo_deletes_by_user',
              characteristics: %i[user],
              limit: 6,
              period: 1.minute,
              action: :block
            },
            bulk_import: {
              limiter_name: 'applimiter_bulk_import',
              rule_name: 'limit_bulk_imports_by_user',
              characteristics: %i[user],
              limit: 6,
              period: 1.minute,
              action: :block
            },
            ci_job_processed_subscription: {
              limiter_name: 'applimiter_ci_job_processed_subscription',
              rule_name: 'limit_ci_job_processed_subscriptions_by_project',
              characteristics: %i[project],
              limit: 50,
              period: 1.minute,
              action: :block
            },
            ci_lint: {
              limiter_name: 'applimiter_ci_lint',
              rule_name: 'limit_ci_lint_by_user',
              characteristics: %i[user],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.ci_lint_limit_per_user },
              period: 1.minute,
              action: :block
            },
            ci_pipeline_statuses_subscription: {
              limiter_name: 'applimiter_ci_pipeline_statuses_subscription',
              rule_name: 'limit_ci_pipeline_status_subscriptions_by_project',
              characteristics: %i[project],
              limit: 50,
              period: 1.minute,
              action: :block
            },
            code_suggestions_api_endpoint: {
              limiter_name: 'applimiter_code_suggestions_api_endpoint',
              rule_name: 'limit_code_suggestions_by_user',
              characteristics: %i[user],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.code_suggestions_api_rate_limit },
              period: 1.minute,
              action: :block
            },
            create_organization_api: {
              limiter_name: 'applimiter_create_organization_api',
              rule_name: 'limit_organization_creates_by_user',
              characteristics: %i[user],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.create_organization_api_limit },
              period: 1.minute,
              action: :block
            },
            delete_all_todos: {
              limiter_name: 'applimiter_delete_all_todos',
              rule_name: 'limit_todo_bulk_deletes_by_user',
              characteristics: %i[user],
              limit: 1,
              period: 5.minutes,
              action: :block
            },
            deployment_delete: {
              limiter_name: 'applimiter_deployment_delete',
              rule_name: 'limit_deployment_deletes_by_user',
              characteristics: %i[user],
              limit: 500,
              period: 1.minute,
              action: :block
            },
            downstream_pipeline_trigger: {
              limiter_name: 'applimiter_downstream_pipeline_trigger',
              rule_name: 'limit_downstream_pipeline_triggers_by_project_user_sha',
              characteristics: %i[project user sha],
              limit: -> {
                Gitlab::CurrentSettings.current_application_settings.downstream_pipeline_trigger_limit_per_project_user_sha
              },
              period: 1.minute,
              action: :block
            },
            email_verification: {
              limiter_name: 'applimiter_email_verification',
              rule_name: 'limit_email_verifies_by_subject',
              characteristics: %i[subject],
              limit: 10,
              period: 10.minutes,
              action: :block
            },
            email_verification_code_send: {
              limiter_name: 'applimiter_email_verification_code_send',
              rule_name: 'limit_email_verification_sends_by_user',
              characteristics: %i[user],
              limit: 10,
              period: 1.hour,
              action: :block
            },
            expanded_diff_files: {
              limiter_name: 'applimiter_expanded_diff_files',
              rule_name: 'limit_expanded_diff_files_by_user_or_ip',
              characteristics: %i[user ip],
              limit: 6,
              period: 1.minute,
              action: :block
            },
            feature_library_search: {
              limiter_name: 'applimiter_feature_library_search',
              rule_name: 'limit_feature_library_searches_by_user',
              characteristics: %i[user],
              limit: 60,
              period: 1.minute,
              action: :block
            },
            fetch_google_ip_list: {
              limiter_name: 'applimiter_fetch_google_ip_list',
              rule_name: 'limit_google_ip_list_fetches_by_scope',
              characteristics: %i[scope],
              limit: 10,
              period: 1.minute,
              action: :block
            },
            fogbugz_import: {
              limiter_name: 'applimiter_fogbugz_import',
              rule_name: 'limit_fogbugz_imports_by_user',
              characteristics: %i[user],
              limit: 1,
              period: 1.minute,
              action: :block
            },
            geo_proxy: {
              limiter_name: 'applimiter_geo_proxy',
              rule_name: 'limit_geo_proxy_requests_by_ip',
              characteristics: %i[ip],
              limit: 60,
              period: 1.minute,
              action: :block
            },
            gitea_import: {
              limiter_name: 'applimiter_gitea_import',
              rule_name: 'limit_gitea_imports_by_user',
              characteristics: %i[user],
              limit: 6,
              period: 1.minute,
              action: :block
            },
            github_import: {
              limiter_name: 'applimiter_github_import',
              rule_name: 'limit_github_imports_by_user',
              characteristics: %i[user],
              limit: 6,
              period: 1.minute,
              action: :block
            },
            gitlab_shell_operation: {
              limiter_name: 'applimiter_gitlab_shell_operation',
              rule_name: 'limit_gitlab_shell_operations_by_action_project_actor',
              # `:repo_path`, not `:project`: lib/api/internal/base.rb passes
              # params[:project] as a repo-path String (see
              # lib/api/helpers/internal_helpers.rb:173), not a Project AR.
              # Naming the slot `:project` reserved it for AR routing, which
              # left only two primitive slots for three String values
              # (action, path, ip) on the untrusted-IP branch and silently
              # dropped the IP, collapsing every untrusted-IP client to a
              # given repo into one Redis counter.
              characteristics: %i[action repo_path user key ip],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.gitlab_shell_operation_limit },
              period: 1.minute,
              action: :block
            },
            glql: {
              limiter_name: 'applimiter_glql',
              rule_name: 'limit_glql_queries_by_query_sha',
              characteristics: %i[query_sha],
              limit: 1,
              period: 15.minutes,
              action: :block
            },
            group_api: {
              limiter_name: 'applimiter_group_api',
              rule_name: 'limit_group_api_by_user_or_ip',
              characteristics: %i[user ip],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.group_api_limit },
              period: 1.minute,
              action: :block
            },
            group_archive_unarchive_api: {
              limiter_name: 'applimiter_group_archive_unarchive_api',
              rule_name: 'limit_group_archive_unarchive_api_by_user_or_ip',
              characteristics: %i[user ip],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.group_archive_unarchive_api_limit },
              period: 1.minute,
              action: :block
            },
            group_download_export: {
              limiter_name: 'applimiter_group_download_export',
              rule_name: 'limit_group_export_downloads_by_user_group',
              characteristics: %i[user group],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.group_download_export_limit },
              period: 1.minute,
              action: :block
            },
            group_export: {
              limiter_name: 'applimiter_group_export',
              rule_name: 'limit_group_exports_by_user',
              characteristics: %i[user],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.group_export_limit },
              period: 1.minute,
              action: :block
            },
            group_import: {
              limiter_name: 'applimiter_group_import',
              rule_name: 'limit_group_imports_by_user',
              characteristics: %i[user],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.group_import_limit },
              period: 1.minute,
              action: :block
            },
            group_invited_groups_api: {
              limiter_name: 'applimiter_group_invited_groups_api',
              rule_name: 'limit_group_invited_groups_api_by_user_or_ip',
              characteristics: %i[user ip],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.group_invited_groups_api_limit },
              period: 1.minute,
              action: :block
            },
            group_projects_api: {
              limiter_name: 'applimiter_group_projects_api',
              rule_name: 'limit_group_projects_api_by_user_or_ip',
              characteristics: %i[user ip],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.group_projects_api_limit },
              period: 1.minute,
              action: :block
            },
            group_shared_groups_api: {
              limiter_name: 'applimiter_group_shared_groups_api',
              rule_name: 'limit_group_shared_groups_api_by_user_or_ip',
              characteristics: %i[user ip],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.group_shared_groups_api_limit },
              period: 1.minute,
              action: :block
            },
            groups_api: {
              limiter_name: 'applimiter_groups_api',
              rule_name: 'limit_groups_api_by_user_or_ip',
              characteristics: %i[user ip],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.groups_api_limit },
              period: 1.minute,
              action: :block
            },
            import_source_user_notification: {
              limiter_name: 'applimiter_import_source_user_notification',
              rule_name: 'limit_import_source_user_notifications_by_source_user',
              characteristics: %i[import_source_user],
              limit: 1,
              period: 8.hours,
              action: :block
            },
            issues_create: {
              limiter_name: 'applimiter_issues_create',
              rule_name: 'limit_issues_by_project_user_external_author',
              characteristics: %i[project user external_author],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.issues_create_limit },
              period: 1.minute,
              action: :block
            },
            jobs_index: {
              limiter_name: 'applimiter_jobs_index',
              rule_name: 'limit_jobs_index_by_user',
              characteristics: %i[user],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.project_jobs_api_rate_limit },
              period: 1.minute,
              action: :block
            },
            large_blob_download: {
              limiter_name: 'applimiter_large_blob_download',
              rule_name: 'limit_large_blob_downloads_by_project',
              characteristics: %i[project],
              limit: 5,
              period: 1.minute,
              action: :block
            },
            members_delete: {
              limiter_name: 'applimiter_members_delete',
              rule_name: 'limit_member_deletes_by_source_user',
              characteristics: %i[project group user],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.members_delete_limit },
              period: 1.minute,
              action: :block
            },
            namespace_exists: {
              limiter_name: 'applimiter_namespace_exists',
              rule_name: 'limit_namespace_existence_checks_by_user',
              characteristics: %i[user],
              limit: 20,
              period: 1.minute,
              action: :block
            },
            notes_create: {
              limiter_name: 'applimiter_notes_create',
              rule_name: 'limit_notes_by_user',
              characteristics: %i[user],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.notes_create_limit },
              period: 1.minute,
              action: :block
            },
            notification_emails: {
              limiter_name: 'applimiter_notification_emails',
              rule_name: 'limit_notification_emails_by_parent_user',
              characteristics: %i[project group user],
              limit: 1000,
              period: 1.day,
              action: :block
            },
            oauth_dynamic_registration: {
              limiter_name: 'applimiter_oauth_dynamic_registration',
              rule_name: 'limit_oauth_registrations_by_ip',
              characteristics: %i[ip],
              limit: 5,
              period: 1.hour,
              action: :block
            },
            offline_export: {
              limiter_name: 'applimiter_offline_export',
              rule_name: 'limit_offline_exports_by_user',
              characteristics: %i[user],
              limit: 6,
              period: 1.minute,
              action: :block
            },
            offline_import: {
              limiter_name: 'applimiter_offline_import',
              rule_name: 'limit_offline_imports_by_user',
              characteristics: %i[user],
              limit: 6,
              period: 1.minute,
              action: :block
            },
            permanent_email_failure: {
              limiter_name: 'applimiter_permanent_email_failure',
              rule_name: 'limit_permanent_email_failures_by_email',
              characteristics: %i[email],
              limit: 5,
              period: 1.day,
              action: :block
            },
            phone_verification_send_code: {
              limiter_name: 'applimiter_phone_verification_send_code',
              rule_name: 'limit_phone_verification_sends_by_user',
              characteristics: %i[user],
              limit: 5,
              period: 1.day,
              action: :block
            },
            phone_verification_verify_code: {
              limiter_name: 'applimiter_phone_verification_verify_code',
              rule_name: 'limit_phone_verification_verifies_by_user',
              characteristics: %i[user],
              limit: 5,
              period: 1.day,
              action: :block
            },
            pipelines_create: {
              limiter_name: 'applimiter_pipelines_create',
              rule_name: 'limit_pipelines_by_project_user_sha',
              characteristics: %i[project user sha],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.pipeline_limit_per_project_user_sha },
              period: 1.minute,
              action: :block
            },
            pipelines_created_per_user: {
              limiter_name: 'applimiter_pipelines_created_per_user',
              rule_name: 'limit_pipelines_by_user',
              characteristics: %i[user],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.pipeline_limit_per_user },
              period: 1.minute,
              action: :block
            },
            placeholder_reassignment: {
              limiter_name: 'applimiter_placeholder_reassignment',
              rule_name: 'limit_placeholder_reassignments_by_user',
              characteristics: %i[user],
              limit: 5,
              period: 1.minute,
              action: :block
            },
            play_pipeline_schedule: {
              limiter_name: 'applimiter_play_pipeline_schedule',
              rule_name: 'limit_pipeline_schedule_plays_by_user_schedule',
              characteristics: %i[user ci_pipeline_schedule],
              limit: 1,
              period: 1.minute,
              action: :block
            },
            profile_add_new_email: {
              limiter_name: 'applimiter_profile_add_new_email',
              rule_name: 'limit_profile_email_adds_by_user',
              characteristics: %i[user],
              limit: 5,
              period: 1.minute,
              action: :block
            },
            profile_resend_email_confirmation: {
              limiter_name: 'applimiter_profile_resend_email_confirmation',
              rule_name: 'limit_profile_email_confirm_resends_by_user',
              characteristics: %i[user],
              limit: 5,
              period: 1.minute,
              action: :block
            },
            profile_update_username: {
              limiter_name: 'applimiter_profile_update_username',
              rule_name: 'limit_profile_username_updates_by_user',
              characteristics: %i[user],
              limit: 10,
              period: 1.minute,
              action: :block
            },
            project_api: {
              limiter_name: 'applimiter_project_api',
              rule_name: 'limit_project_api_by_user_or_ip',
              characteristics: %i[user ip],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.project_api_limit },
              period: 1.minute,
              action: :block
            },
            project_download_export: {
              limiter_name: 'applimiter_project_download_export',
              rule_name: 'limit_project_export_downloads_by_user_project',
              characteristics: %i[user project],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.project_download_export_limit },
              period: 1.minute,
              action: :block
            },
            project_export: {
              limiter_name: 'applimiter_project_export',
              rule_name: 'limit_project_exports_by_user',
              characteristics: %i[user],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.project_export_limit },
              period: 1.minute,
              action: :block
            },
            project_fork_sync: {
              limiter_name: 'applimiter_project_fork_sync',
              rule_name: 'limit_project_fork_syncs_by_project_user',
              characteristics: %i[project user],
              limit: 10,
              period: 30.minutes,
              action: :block
            },
            project_generate_new_export: {
              limiter_name: 'applimiter_project_generate_new_export',
              rule_name: 'limit_project_export_generations_by_user',
              characteristics: %i[user],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.project_export_limit },
              period: 1.minute,
              action: :block
            },
            project_import: {
              limiter_name: 'applimiter_project_import',
              rule_name: 'limit_project_imports_by_user_action',
              characteristics: %i[user action],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.project_import_limit },
              period: 1.minute,
              action: :block
            },
            project_invited_groups_api: {
              limiter_name: 'applimiter_project_invited_groups_api',
              rule_name: 'limit_project_invited_groups_api_by_user_or_ip',
              characteristics: %i[user ip],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.project_invited_groups_api_limit },
              period: 1.minute,
              action: :block
            },
            project_members_api: {
              limiter_name: 'applimiter_project_members_api',
              rule_name: 'limit_project_members_api_by_user_or_ip',
              characteristics: %i[user ip],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.project_members_api_limit },
              period: 1.minute,
              action: :block
            },
            project_repositories_archive: {
              limiter_name: 'applimiter_project_repositories_archive',
              rule_name: 'limit_project_repository_archives_by_project_user',
              characteristics: %i[project user],
              limit: 5,
              period: 1.minute,
              action: :block
            },
            project_repositories_changelog: {
              limiter_name: 'applimiter_project_repositories_changelog',
              rule_name: 'limit_project_repository_changelogs_by_user_project',
              characteristics: %i[user project],
              limit: 5,
              period: 1.minute,
              action: :block
            },
            project_repositories_health: {
              limiter_name: 'applimiter_project_repositories_health',
              rule_name: 'limit_project_repository_health_by_project',
              characteristics: %i[project],
              limit: 5,
              period: 1.hour,
              action: :block
            },
            project_testing_integration: {
              limiter_name: 'applimiter_project_testing_integration',
              rule_name: 'limit_integration_tests_by_project_user',
              characteristics: %i[project user],
              limit: 5,
              period: 1.minute,
              action: :block
            },
            projects_api: {
              limiter_name: 'applimiter_projects_api',
              rule_name: 'limit_projects_api_by_user_or_ip',
              characteristics: %i[user ip],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.projects_api_limit },
              period: 10.minutes,
              action: :block
            },
            projects_api_rate_limit_unauthenticated: {
              limiter_name: 'applimiter_projects_api_rate_limit_unauthenticated',
              rule_name: 'limit_projects_api_by_ip',
              characteristics: %i[ip],
              limit: -> {
                Gitlab::CurrentSettings.current_application_settings.projects_api_rate_limit_unauthenticated
              },
              period: 10.minutes,
              action: :block
            },
            raw_blob: {
              limiter_name: 'applimiter_raw_blob',
              rule_name: 'limit_raw_blobs_by_project_path',
              characteristics: %i[project path],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.raw_blob_request_limit },
              period: 1.minute,
              action: :block
            },
            raw_blob_unauthenticated: {
              limiter_name: 'applimiter_raw_blob_unauthenticated',
              rule_name: 'limit_raw_blobs_by_project',
              characteristics: %i[project],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.raw_blob_request_limit_unauthenticated },
              period: 1.minute,
              action: :block
            },
            runner_jobs_api: {
              limiter_name: 'applimiter_runner_jobs_api',
              rule_name: 'limit_runner_jobs_by_job_token',
              characteristics: %i[job_token_sha],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.runner_jobs_endpoints_api_limit },
              period: 1.minute,
              action: :block
            },
            runner_jobs_patch_trace_api: {
              limiter_name: 'applimiter_runner_jobs_patch_trace_api',
              rule_name: 'limit_runner_job_traces_by_job_token',
              characteristics: %i[job_token_sha],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.runner_jobs_patch_trace_api_limit },
              period: 1.minute,
              action: :block
            },
            runner_jobs_request_api: {
              limiter_name: 'applimiter_runner_jobs_request_api',
              rule_name: 'limit_runner_job_requests_by_runner_token',
              characteristics: %i[runner_token_sha],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.runner_jobs_request_api_limit },
              period: 1.minute,
              action: :block
            },
            search_index_integrity: {
              limiter_name: 'applimiter_search_index_integrity',
              rule_name: 'limit_search_index_integrity_checks_by_project_or_group',
              characteristics: %i[project group],
              limit: 1,
              period: 30.minutes,
              action: :block
            },
            search_rate_limit: {
              limiter_name: 'applimiter_search_rate_limit',
              rule_name: 'limit_searches_by_user_scope',
              characteristics: %i[user search_scope],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.search_rate_limit },
              period: 1.minute,
              action: :block
            },
            search_rate_limit_unauthenticated: {
              limiter_name: 'applimiter_search_rate_limit_unauthenticated',
              rule_name: 'limit_searches_by_ip',
              characteristics: %i[ip],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.search_rate_limit_unauthenticated },
              period: 1.minute,
              action: :block
            },
            service_account_creation: {
              limiter_name: 'applimiter_service_account_creation',
              rule_name: 'limit_service_account_creates_by_user',
              characteristics: %i[user],
              limit: 10,
              period: 1.minute,
              action: :block
            },
            temporary_email_failure: {
              limiter_name: 'applimiter_temporary_email_failure',
              rule_name: 'limit_temporary_email_failures_by_email',
              characteristics: %i[email],
              limit: 300,
              period: 1.day,
              action: :block
            },
            token_exchange: {
              limiter_name: 'applimiter_token_exchange',
              rule_name: 'limit_token_exchanges_by_user',
              characteristics: %i[user],
              limit: 60,
              period: 1.minute,
              action: :block
            },
            update_environment_canary_ingress: {
              limiter_name: 'applimiter_update_environment_canary_ingress',
              rule_name: 'limit_canary_ingress_updates_by_environment',
              characteristics: %i[environment],
              limit: 1,
              period: 1.minute,
              action: :block
            },
            update_namespace_name: {
              limiter_name: 'applimiter_update_namespace_name',
              rule_name: 'limit_namespace_name_updates_by_namespace',
              characteristics: %i[namespace],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.update_namespace_name_rate_limit },
              period: 1.hour,
              action: :block
            },
            user_contributed_projects_api: {
              limiter_name: 'applimiter_user_contributed_projects_api',
              rule_name: 'limit_user_contributed_projects_api_by_user_or_ip',
              characteristics: %i[user ip],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.user_contributed_projects_api_limit },
              period: 1.minute,
              action: :block
            },
            user_followers: {
              limiter_name: 'applimiter_user_followers',
              rule_name: 'limit_user_followers_api_by_user_or_ip',
              characteristics: %i[user ip],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.users_api_limit_followers },
              period: 1.minute,
              action: :block
            },
            user_following: {
              limiter_name: 'applimiter_user_following',
              rule_name: 'limit_user_following_api_by_user_or_ip',
              characteristics: %i[user ip],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.users_api_limit_following },
              period: 1.minute,
              action: :block
            },
            user_gpg_key: {
              limiter_name: 'applimiter_user_gpg_key',
              rule_name: 'limit_user_gpg_key_api_by_user_or_ip',
              characteristics: %i[user ip],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.users_api_limit_gpg_key },
              period: 1.minute,
              action: :block
            },
            user_gpg_keys: {
              limiter_name: 'applimiter_user_gpg_keys',
              rule_name: 'limit_user_gpg_keys_api_by_user_or_ip',
              characteristics: %i[user ip],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.users_api_limit_gpg_keys },
              period: 1.minute,
              action: :block
            },
            user_large_commit_request: {
              limiter_name: 'applimiter_user_large_commit_request',
              rule_name: 'limit_large_commit_requests_by_user',
              characteristics: %i[user],
              limit: 3,
              period: 30.seconds,
              action: :block
            },
            user_projects_api: {
              limiter_name: 'applimiter_user_projects_api',
              rule_name: 'limit_user_projects_api_by_user_or_ip',
              characteristics: %i[user ip],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.user_projects_api_limit },
              period: 1.minute,
              action: :block
            },
            user_sign_in: {
              limiter_name: 'applimiter_user_sign_in',
              rule_name: 'limit_signins_by_user',
              characteristics: %i[user],
              limit: 5,
              period: 10.minutes,
              action: :block
            },
            user_sign_up: {
              limiter_name: 'applimiter_user_sign_up',
              rule_name: 'limit_signups_by_ip',
              characteristics: %i[ip],
              limit: 20,
              period: 1.minute,
              action: :block
            },
            user_ssh_key: {
              limiter_name: 'applimiter_user_ssh_key',
              rule_name: 'limit_user_ssh_key_api_by_user_or_ip',
              characteristics: %i[user ip],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.users_api_limit_ssh_key },
              period: 1.minute,
              action: :block
            },
            user_ssh_keys: {
              limiter_name: 'applimiter_user_ssh_keys',
              rule_name: 'limit_user_ssh_keys_api_by_user_or_ip',
              characteristics: %i[user ip],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.users_api_limit_ssh_keys },
              period: 1.minute,
              action: :block
            },
            user_starred_projects_api: {
              limiter_name: 'applimiter_user_starred_projects_api',
              rule_name: 'limit_user_starred_projects_api_by_user_or_ip',
              characteristics: %i[user ip],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.user_starred_projects_api_limit },
              period: 1.minute,
              action: :block
            },
            user_status: {
              limiter_name: 'applimiter_user_status',
              rule_name: 'limit_user_status_api_by_user_or_ip',
              characteristics: %i[user ip],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.users_api_limit_status },
              period: 1.minute,
              action: :block
            },
            username_exists: {
              limiter_name: 'applimiter_username_exists',
              rule_name: 'limit_username_existence_checks_by_ip',
              characteristics: %i[ip],
              limit: 20,
              period: 1.minute,
              action: :block
            },
            users_get_by_id: {
              limiter_name: 'applimiter_users_get_by_id',
              rule_name: 'limit_user_lookups_by_user',
              characteristics: %i[user],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.users_get_by_id_limit },
              period: 10.minutes,
              action: :block
            },
            # web_hook_calls{,_low,_mid} carry no static threshold: the limit
            # is looked up per namespace from PlanLimits and passed in via the
            # caller's `threshold:` argument. They therefore omit `limit:` (it
            # resolves to 0, exactly as the legacy hash did, which carried no
            # threshold for them). `threshold_from_caller: true` opts the entry
            # out of the adapter's threshold-override bail so the caller's value
            # is forwarded through to labkit's one-arity limit callable via
            # rule_context. The `1.minute` period is the registry value and is
            # not caller-controlled.
            web_hook_calls: {
              limiter_name: 'applimiter_web_hook_calls',
              rule_name: 'limit_web_hook_calls_by_namespace',
              characteristics: %i[namespace],
              period: 1.minute,
              threshold_from_caller: true,
              action: :block
            },
            web_hook_calls_low: {
              limiter_name: 'applimiter_web_hook_calls_low',
              rule_name: 'limit_web_hook_calls_low_by_namespace',
              characteristics: %i[namespace],
              period: 1.minute,
              threshold_from_caller: true,
              action: :block
            },
            web_hook_calls_mid: {
              limiter_name: 'applimiter_web_hook_calls_mid',
              rule_name: 'limit_web_hook_calls_mid_by_namespace',
              characteristics: %i[namespace],
              period: 1.minute,
              threshold_from_caller: true,
              action: :block
            },
            web_hook_event_resend: {
              limiter_name: 'applimiter_web_hook_event_resend',
              rule_name: 'limit_web_hook_event_resends_by_parent_user',
              characteristics: %i[project group user],
              limit: 5,
              period: 1.minute,
              action: :block
            },
            web_hook_test: {
              limiter_name: 'applimiter_web_hook_test',
              rule_name: 'limit_web_hook_tests_by_parent_user',
              characteristics: %i[project group user],
              limit: 5,
              period: 1.minute,
              action: :block
            },
            # Per-database Sidekiq resource-usage (DB duration) limits,
            # one Limiter per database. Cost-mode (the per-job DB duration is the
            # `check(cost:)` value, not a call count). threshold and interval are
            # both caller-supplied: SidekiqLimits.limits_for resolves the worker's
            # urgency rule and any ApplicationSetting override upstream, so the
            # labkit Rule must use that resolved value (not a static constant).
            # They therefore carry no static limit/period; both arrive per call
            # via rule_context and these keys are absent from rate_limits.
            main_db_duration_limit_per_worker: {
              limiter_name: 'applimiter_main_db_duration_limit_per_worker',
              rule_name: 'limit_main_db_duration_per_worker',
              characteristics: %i[worker_name],
              action: :block,
              cost_mode: true
            },
            ci_db_duration_limit_per_worker: {
              limiter_name: 'applimiter_ci_db_duration_limit_per_worker',
              rule_name: 'limit_ci_db_duration_per_worker',
              characteristics: %i[worker_name],
              action: :block,
              cost_mode: true
            },
            sec_db_duration_limit_per_worker: {
              limiter_name: 'applimiter_sec_db_duration_limit_per_worker',
              rule_name: 'limit_sec_db_duration_per_worker',
              characteristics: %i[worker_name],
              action: :block,
              cost_mode: true
            }
          }
        end
      end
    end
  end
end

Gitlab::ApplicationRateLimiter::LabkitAdapter::SupportedRateLimits.prepend_mod
