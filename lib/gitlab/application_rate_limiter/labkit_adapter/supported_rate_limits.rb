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
      #   action:          informational; the adapter owns enforcement
      #                    via the *_enforce feature flag.
      #   flag_scope:      optional. Absent => per-key flag (cohort 1);
      #                    set => cohort-wide flag pair, e.g. :cohort_2.
      #
      # Cohort 3 (`flag_scope: :cohort_3`) groups keys whose call graph
      # includes one or more `.peek` invocations; registering them was
      # blocked on labkit's `Limiter#peek`. Both peek and non-peek callers
      # of these keys route through the adapter so the labkit and legacy
      # counters increment from the same call sites and shadow comparisons
      # remain meaningful. `web_hook_calls{,_low,_mid}` are deliberately
      # excluded: every caller passes a `threshold:` override which the
      # adapter cannot honour and routes to legacy via record_override.
      #
      # Keys deliberately not registered (EE-only without a current call
      # site; partner APIs with sub-second intervals) are documented in
      # the EE file's exclusion comment.
      module SupportedRateLimits
        def self.all
          @all ||= entries.freeze
        end

        def self.entries
          {
            ai_action: {
              limiter_name: 'applimiter_ai_action',
              rule_name: 'limit_ai_actions_by_user',
              characteristics: %i[user],
              action: :block,
              flag_scope: :cohort_2
            },
            auto_rollback_deployment: {
              limiter_name: 'applimiter_auto_rollback_deployment',
              rule_name: 'limit_auto_rollbacks_by_environment',
              characteristics: %i[environment],
              action: :block,
              flag_scope: :cohort_2
            },
            autocomplete_users: {
              limiter_name: 'applimiter_autocomplete_users',
              rule_name: 'limit_user_autocompletes_by_user',
              characteristics: %i[user],
              action: :block,
              flag_scope: :cohort_2
            },
            autocomplete_users_unauthenticated: {
              limiter_name: 'applimiter_autocomplete_users_unauthenticated',
              rule_name: 'limit_user_autocompletes_by_ip',
              characteristics: %i[ip],
              action: :block,
              flag_scope: :cohort_2
            },
            bitbucket_server_import: {
              limiter_name: 'applimiter_bitbucket_server_import',
              rule_name: 'limit_bitbucket_server_imports_by_user',
              characteristics: %i[user],
              action: :block,
              flag_scope: :cohort_2
            },
            bulk_delete_todos: {
              limiter_name: 'applimiter_bulk_delete_todos',
              rule_name: 'limit_bulk_todo_deletes_by_user',
              characteristics: %i[user],
              action: :block,
              flag_scope: :cohort_2
            },
            bulk_import: {
              limiter_name: 'applimiter_bulk_import',
              rule_name: 'limit_bulk_imports_by_user',
              characteristics: %i[user],
              action: :block,
              flag_scope: :cohort_2
            },
            ci_job_processed_subscription: {
              limiter_name: 'applimiter_ci_job_processed_subscription',
              rule_name: 'limit_ci_job_processed_subscriptions_by_project',
              characteristics: %i[project],
              action: :block,
              flag_scope: :cohort_2
            },
            ci_pipeline_statuses_subscription: {
              limiter_name: 'applimiter_ci_pipeline_statuses_subscription',
              rule_name: 'limit_ci_pipeline_status_subscriptions_by_project',
              characteristics: %i[project],
              action: :block,
              flag_scope: :cohort_2
            },
            code_suggestions_api_endpoint: {
              limiter_name: 'applimiter_code_suggestions_api_endpoint',
              rule_name: 'limit_code_suggestions_by_user',
              characteristics: %i[user],
              action: :block,
              flag_scope: :cohort_2
            },
            create_organization_api: {
              limiter_name: 'applimiter_create_organization_api',
              rule_name: 'limit_organization_creates_by_user',
              characteristics: %i[user],
              action: :block,
              flag_scope: :cohort_2
            },
            delete_all_todos: {
              limiter_name: 'applimiter_delete_all_todos',
              rule_name: 'limit_todo_bulk_deletes_by_user',
              characteristics: %i[user],
              action: :block,
              flag_scope: :cohort_2
            },
            downstream_pipeline_trigger: {
              limiter_name: 'applimiter_downstream_pipeline_trigger',
              rule_name: 'limit_downstream_pipeline_triggers_by_project_user_sha',
              characteristics: %i[project user sha],
              action: :block,
              flag_scope: :cohort_2
            },
            email_verification: {
              limiter_name: 'applimiter_email_verification',
              rule_name: 'limit_email_verifies_by_subject',
              characteristics: %i[subject],
              action: :block,
              flag_scope: :cohort_2
            },
            email_verification_code_send: {
              limiter_name: 'applimiter_email_verification_code_send',
              rule_name: 'limit_email_verification_sends_by_user',
              characteristics: %i[user],
              action: :block,
              flag_scope: :cohort_2
            },
            expanded_diff_files: {
              limiter_name: 'applimiter_expanded_diff_files',
              rule_name: 'limit_expanded_diff_files_by_user_or_ip',
              characteristics: %i[user ip],
              action: :block,
              flag_scope: :cohort_2
            },
            fetch_google_ip_list: {
              limiter_name: 'applimiter_fetch_google_ip_list',
              rule_name: 'limit_google_ip_list_fetches_by_scope',
              characteristics: %i[scope],
              action: :block,
              flag_scope: :cohort_2
            },
            fogbugz_import: {
              limiter_name: 'applimiter_fogbugz_import',
              rule_name: 'limit_fogbugz_imports_by_user',
              characteristics: %i[user],
              action: :block,
              flag_scope: :cohort_2
            },
            geo_proxy: {
              limiter_name: 'applimiter_geo_proxy',
              rule_name: 'limit_geo_proxy_requests_by_ip',
              characteristics: %i[ip],
              action: :block,
              flag_scope: :cohort_2
            },
            gitea_import: {
              limiter_name: 'applimiter_gitea_import',
              rule_name: 'limit_gitea_imports_by_user',
              characteristics: %i[user],
              action: :block,
              flag_scope: :cohort_2
            },
            github_import: {
              limiter_name: 'applimiter_github_import',
              rule_name: 'limit_github_imports_by_user',
              characteristics: %i[user],
              action: :block,
              flag_scope: :cohort_2
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
              action: :block,
              flag_scope: :cohort_2
            },
            glql: {
              limiter_name: 'applimiter_glql',
              rule_name: 'limit_glql_queries_by_query_sha',
              characteristics: %i[query_sha],
              action: :block,
              flag_scope: :cohort_3
            },
            group_api: {
              limiter_name: 'applimiter_group_api',
              rule_name: 'limit_group_api_by_user_or_ip',
              characteristics: %i[user ip],
              action: :block,
              flag_scope: :cohort_2
            },
            group_archive_unarchive_api: {
              limiter_name: 'applimiter_group_archive_unarchive_api',
              rule_name: 'limit_group_archive_unarchive_api_by_user_or_ip',
              characteristics: %i[user ip],
              action: :block,
              flag_scope: :cohort_2
            },
            group_download_export: {
              limiter_name: 'applimiter_group_download_export',
              rule_name: 'limit_group_export_downloads_by_user_group',
              characteristics: %i[user group],
              action: :block,
              flag_scope: :cohort_2
            },
            group_export: {
              limiter_name: 'applimiter_group_export',
              rule_name: 'limit_group_exports_by_user',
              characteristics: %i[user],
              action: :block,
              flag_scope: :cohort_2
            },
            group_import: {
              limiter_name: 'applimiter_group_import',
              rule_name: 'limit_group_imports_by_user',
              characteristics: %i[user],
              action: :block,
              flag_scope: :cohort_2
            },
            group_invited_groups_api: {
              limiter_name: 'applimiter_group_invited_groups_api',
              rule_name: 'limit_group_invited_groups_api_by_user_or_ip',
              characteristics: %i[user ip],
              action: :block,
              flag_scope: :cohort_2
            },
            group_projects_api: {
              limiter_name: 'applimiter_group_projects_api',
              rule_name: 'limit_group_projects_api_by_user_or_ip',
              characteristics: %i[user ip],
              action: :block,
              flag_scope: :cohort_2
            },
            group_shared_groups_api: {
              limiter_name: 'applimiter_group_shared_groups_api',
              rule_name: 'limit_group_shared_groups_api_by_user_or_ip',
              characteristics: %i[user ip],
              action: :block,
              flag_scope: :cohort_2
            },
            groups_api: {
              limiter_name: 'applimiter_groups_api',
              rule_name: 'limit_groups_api_by_user_or_ip',
              characteristics: %i[user ip],
              action: :block,
              flag_scope: :cohort_2
            },
            import_source_user_notification: {
              limiter_name: 'applimiter_import_source_user_notification',
              rule_name: 'limit_import_source_user_notifications_by_source_user',
              characteristics: %i[import_source_user],
              action: :block,
              flag_scope: :cohort_2
            },
            issues_create: {
              limiter_name: 'applimiter_issues_create',
              rule_name: 'limit_issues_by_project_user_external_author',
              characteristics: %i[project user external_author],
              action: :block,
              flag_scope: :cohort_2
            },
            jobs_index: {
              limiter_name: 'applimiter_jobs_index',
              rule_name: 'limit_jobs_index_by_user',
              characteristics: %i[user],
              action: :block,
              flag_scope: :cohort_2
            },
            large_blob_download: {
              limiter_name: 'applimiter_large_blob_download',
              rule_name: 'limit_large_blob_downloads_by_project',
              characteristics: %i[project],
              action: :block,
              flag_scope: :cohort_2
            },
            members_delete: {
              limiter_name: 'applimiter_members_delete',
              rule_name: 'limit_member_deletes_by_source_user',
              characteristics: %i[project group user],
              action: :block,
              flag_scope: :cohort_2
            },
            namespace_exists: {
              limiter_name: 'applimiter_namespace_exists',
              rule_name: 'limit_namespace_existence_checks_by_user',
              characteristics: %i[user],
              action: :block,
              flag_scope: :cohort_2
            },
            notes_create: {
              limiter_name: 'applimiter_notes_create',
              rule_name: 'limit_notes_by_user',
              characteristics: %i[user],
              action: :block
            },
            oauth_dynamic_registration: {
              limiter_name: 'applimiter_oauth_dynamic_registration',
              rule_name: 'limit_oauth_registrations_by_ip',
              characteristics: %i[ip],
              action: :block,
              flag_scope: :cohort_2
            },
            offline_export: {
              limiter_name: 'applimiter_offline_export',
              rule_name: 'limit_offline_exports_by_user',
              characteristics: %i[user],
              action: :block,
              flag_scope: :cohort_2
            },
            offline_import: {
              limiter_name: 'applimiter_offline_import',
              rule_name: 'limit_offline_imports_by_user',
              characteristics: %i[user],
              action: :block,
              flag_scope: :cohort_2
            },
            permanent_email_failure: {
              limiter_name: 'applimiter_permanent_email_failure',
              rule_name: 'limit_permanent_email_failures_by_email',
              characteristics: %i[email],
              action: :block,
              flag_scope: :cohort_3
            },
            phone_verification_send_code: {
              limiter_name: 'applimiter_phone_verification_send_code',
              rule_name: 'limit_phone_verification_sends_by_user',
              characteristics: %i[user],
              action: :block,
              flag_scope: :cohort_2
            },
            phone_verification_verify_code: {
              limiter_name: 'applimiter_phone_verification_verify_code',
              rule_name: 'limit_phone_verification_verifies_by_user',
              characteristics: %i[user],
              action: :block,
              flag_scope: :cohort_2
            },
            pipelines_create: {
              limiter_name: 'applimiter_pipelines_create',
              rule_name: 'limit_pipelines_by_project_user_sha',
              characteristics: %i[project user sha],
              action: :block
            },
            pipelines_created_per_user: {
              limiter_name: 'applimiter_pipelines_created_per_user',
              rule_name: 'limit_pipelines_by_user',
              characteristics: %i[user],
              action: :block,
              flag_scope: :cohort_2
            },
            play_pipeline_schedule: {
              limiter_name: 'applimiter_play_pipeline_schedule',
              rule_name: 'limit_pipeline_schedule_plays_by_user_schedule',
              characteristics: %i[user ci_pipeline_schedule],
              action: :block,
              flag_scope: :cohort_2
            },
            profile_add_new_email: {
              limiter_name: 'applimiter_profile_add_new_email',
              rule_name: 'limit_profile_email_adds_by_user',
              characteristics: %i[user],
              action: :block,
              flag_scope: :cohort_2
            },
            profile_resend_email_confirmation: {
              limiter_name: 'applimiter_profile_resend_email_confirmation',
              rule_name: 'limit_profile_email_confirm_resends_by_user',
              characteristics: %i[user],
              action: :block,
              flag_scope: :cohort_2
            },
            profile_update_username: {
              limiter_name: 'applimiter_profile_update_username',
              rule_name: 'limit_profile_username_updates_by_user',
              characteristics: %i[user],
              action: :block,
              flag_scope: :cohort_2
            },
            project_api: {
              limiter_name: 'applimiter_project_api',
              rule_name: 'limit_project_api_by_user_or_ip',
              characteristics: %i[user ip],
              action: :block,
              flag_scope: :cohort_2
            },
            project_download_export: {
              limiter_name: 'applimiter_project_download_export',
              rule_name: 'limit_project_export_downloads_by_user_project',
              characteristics: %i[user project],
              action: :block,
              flag_scope: :cohort_2
            },
            project_export: {
              limiter_name: 'applimiter_project_export',
              rule_name: 'limit_project_exports_by_user',
              characteristics: %i[user],
              action: :block,
              flag_scope: :cohort_2
            },
            project_fork_sync: {
              limiter_name: 'applimiter_project_fork_sync',
              rule_name: 'limit_project_fork_syncs_by_project_user',
              characteristics: %i[project user],
              action: :block,
              flag_scope: :cohort_2
            },
            project_import: {
              limiter_name: 'applimiter_project_import',
              rule_name: 'limit_project_imports_by_user_action',
              characteristics: %i[user action],
              action: :block,
              flag_scope: :cohort_2
            },
            project_invited_groups_api: {
              limiter_name: 'applimiter_project_invited_groups_api',
              rule_name: 'limit_project_invited_groups_api_by_user_or_ip',
              characteristics: %i[user ip],
              action: :block,
              flag_scope: :cohort_2
            },
            project_members_api: {
              limiter_name: 'applimiter_project_members_api',
              rule_name: 'limit_project_members_api_by_user_or_ip',
              characteristics: %i[user ip],
              action: :block,
              flag_scope: :cohort_2
            },
            project_repositories_archive: {
              limiter_name: 'applimiter_project_repositories_archive',
              rule_name: 'limit_project_repository_archives_by_project_user',
              characteristics: %i[project user],
              action: :block,
              flag_scope: :cohort_2
            },
            project_repositories_changelog: {
              limiter_name: 'applimiter_project_repositories_changelog',
              rule_name: 'limit_project_repository_changelogs_by_user_project',
              characteristics: %i[user project],
              action: :block,
              flag_scope: :cohort_2
            },
            project_repositories_health: {
              limiter_name: 'applimiter_project_repositories_health',
              rule_name: 'limit_project_repository_health_by_project',
              characteristics: %i[project],
              action: :block,
              flag_scope: :cohort_2
            },
            project_testing_integration: {
              limiter_name: 'applimiter_project_testing_integration',
              rule_name: 'limit_integration_tests_by_project_user',
              characteristics: %i[project user],
              action: :block,
              flag_scope: :cohort_2
            },
            projects_api: {
              limiter_name: 'applimiter_projects_api',
              rule_name: 'limit_projects_api_by_user_or_ip',
              characteristics: %i[user ip],
              action: :block,
              flag_scope: :cohort_2
            },
            projects_api_rate_limit_unauthenticated: {
              limiter_name: 'applimiter_projects_api_rate_limit_unauthenticated',
              rule_name: 'limit_projects_api_by_ip',
              characteristics: %i[ip],
              action: :block,
              flag_scope: :cohort_2
            },
            raw_blob: {
              limiter_name: 'applimiter_raw_blob',
              rule_name: 'limit_raw_blobs_by_project_path',
              characteristics: %i[project path],
              action: :block,
              flag_scope: :cohort_2
            },
            raw_blob_unauthenticated: {
              limiter_name: 'applimiter_raw_blob_unauthenticated',
              rule_name: 'limit_raw_blobs_by_project',
              characteristics: %i[project],
              action: :block,
              flag_scope: :cohort_2
            },
            runner_jobs_api: {
              limiter_name: 'applimiter_runner_jobs_api',
              rule_name: 'limit_runner_jobs_by_job_token',
              characteristics: %i[job_token_sha],
              action: :block,
              flag_scope: :cohort_2
            },
            runner_jobs_patch_trace_api: {
              limiter_name: 'applimiter_runner_jobs_patch_trace_api',
              rule_name: 'limit_runner_job_traces_by_job_token',
              characteristics: %i[job_token_sha],
              action: :block,
              flag_scope: :cohort_2
            },
            runner_jobs_request_api: {
              limiter_name: 'applimiter_runner_jobs_request_api',
              rule_name: 'limit_runner_job_requests_by_runner_token',
              characteristics: %i[runner_token_sha],
              action: :block,
              flag_scope: :cohort_2
            },
            search_rate_limit: {
              limiter_name: 'applimiter_search_rate_limit',
              rule_name: 'limit_searches_by_user_scope',
              characteristics: %i[user search_scope],
              action: :block
            },
            search_rate_limit_unauthenticated: {
              limiter_name: 'applimiter_search_rate_limit_unauthenticated',
              rule_name: 'limit_searches_by_ip',
              characteristics: %i[ip],
              action: :block,
              flag_scope: :cohort_2
            },
            service_account_creation: {
              limiter_name: 'applimiter_service_account_creation',
              rule_name: 'limit_service_account_creates_by_user',
              characteristics: %i[user],
              action: :block,
              flag_scope: :cohort_2
            },
            temporary_email_failure: {
              limiter_name: 'applimiter_temporary_email_failure',
              rule_name: 'limit_temporary_email_failures_by_email',
              characteristics: %i[email],
              action: :block,
              flag_scope: :cohort_3
            },
            update_environment_canary_ingress: {
              limiter_name: 'applimiter_update_environment_canary_ingress',
              rule_name: 'limit_canary_ingress_updates_by_environment',
              characteristics: %i[environment],
              action: :block,
              flag_scope: :cohort_2
            },
            update_namespace_name: {
              limiter_name: 'applimiter_update_namespace_name',
              rule_name: 'limit_namespace_name_updates_by_namespace',
              characteristics: %i[namespace],
              action: :block,
              flag_scope: :cohort_3
            },
            user_contributed_projects_api: {
              limiter_name: 'applimiter_user_contributed_projects_api',
              rule_name: 'limit_user_contributed_projects_api_by_user_or_ip',
              characteristics: %i[user ip],
              action: :block,
              flag_scope: :cohort_2
            },
            user_followers: {
              limiter_name: 'applimiter_user_followers',
              rule_name: 'limit_user_followers_api_by_user_or_ip',
              characteristics: %i[user ip],
              action: :block,
              flag_scope: :cohort_2
            },
            user_following: {
              limiter_name: 'applimiter_user_following',
              rule_name: 'limit_user_following_api_by_user_or_ip',
              characteristics: %i[user ip],
              action: :block,
              flag_scope: :cohort_2
            },
            user_gpg_key: {
              limiter_name: 'applimiter_user_gpg_key',
              rule_name: 'limit_user_gpg_key_api_by_user_or_ip',
              characteristics: %i[user ip],
              action: :block,
              flag_scope: :cohort_2
            },
            user_gpg_keys: {
              limiter_name: 'applimiter_user_gpg_keys',
              rule_name: 'limit_user_gpg_keys_api_by_user_or_ip',
              characteristics: %i[user ip],
              action: :block,
              flag_scope: :cohort_2
            },
            user_large_commit_request: {
              limiter_name: 'applimiter_user_large_commit_request',
              rule_name: 'limit_large_commit_requests_by_user',
              characteristics: %i[user],
              action: :block,
              flag_scope: :cohort_2
            },
            user_projects_api: {
              limiter_name: 'applimiter_user_projects_api',
              rule_name: 'limit_user_projects_api_by_user_or_ip',
              characteristics: %i[user ip],
              action: :block,
              flag_scope: :cohort_2
            },
            user_sign_in: {
              limiter_name: 'applimiter_user_sign_in',
              rule_name: 'limit_signins_by_user',
              characteristics: %i[user],
              action: :block
            },
            user_sign_up: {
              limiter_name: 'applimiter_user_sign_up',
              rule_name: 'limit_signups_by_ip',
              characteristics: %i[ip],
              action: :block,
              flag_scope: :cohort_2
            },
            user_ssh_key: {
              limiter_name: 'applimiter_user_ssh_key',
              rule_name: 'limit_user_ssh_key_api_by_user_or_ip',
              characteristics: %i[user ip],
              action: :block,
              flag_scope: :cohort_2
            },
            user_ssh_keys: {
              limiter_name: 'applimiter_user_ssh_keys',
              rule_name: 'limit_user_ssh_keys_api_by_user_or_ip',
              characteristics: %i[user ip],
              action: :block,
              flag_scope: :cohort_2
            },
            user_starred_projects_api: {
              limiter_name: 'applimiter_user_starred_projects_api',
              rule_name: 'limit_user_starred_projects_api_by_user_or_ip',
              characteristics: %i[user ip],
              action: :block,
              flag_scope: :cohort_2
            },
            user_status: {
              limiter_name: 'applimiter_user_status',
              rule_name: 'limit_user_status_api_by_user_or_ip',
              characteristics: %i[user ip],
              action: :block,
              flag_scope: :cohort_2
            },
            username_exists: {
              limiter_name: 'applimiter_username_exists',
              rule_name: 'limit_username_existence_checks_by_ip',
              characteristics: %i[ip],
              action: :block,
              flag_scope: :cohort_2
            },
            users_get_by_id: {
              limiter_name: 'applimiter_users_get_by_id',
              rule_name: 'limit_user_lookups_by_user',
              characteristics: %i[user],
              action: :block
            },
            web_hook_event_resend: {
              limiter_name: 'applimiter_web_hook_event_resend',
              rule_name: 'limit_web_hook_event_resends_by_parent_user',
              characteristics: %i[project group user],
              action: :block,
              flag_scope: :cohort_2
            },
            web_hook_test: {
              limiter_name: 'applimiter_web_hook_test',
              rule_name: 'limit_web_hook_tests_by_parent_user',
              characteristics: %i[project group user],
              action: :block,
              flag_scope: :cohort_2
            }
          }
        end
      end
    end
  end
end

Gitlab::ApplicationRateLimiter::LabkitAdapter::SupportedRateLimits.prepend_mod
