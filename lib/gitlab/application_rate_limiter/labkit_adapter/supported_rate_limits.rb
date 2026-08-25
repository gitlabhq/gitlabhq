# frozen_string_literal: true

module Gitlab
  module ApplicationRateLimiter
    module LabkitAdapter
      # Single source of truth for the keys this adapter handles, paired
      # with ee/lib/ee/gitlab/application_rate_limiter/labkit_adapter/
      # supported_rate_limits.rb (EE additions, prepended via prepend_mod).
      #
      # Per-rule conventions:
      #   characteristics: ordered list of identifier slots; AR-typed
      #                    names (see LabkitAdapter#ar_characteristic_types)
      #                    are populated by class-routing, primitives fill
      #                    the remainder positionally. Polymorphic
      #                    positions list every accepted slot; labkit's
      #                    '_unknown_' sentinel fills slots not in scope,
      #                    keeping Redis keys disjoint per real type.
      #   limit:           static threshold (Integer) or a zero-arity callable
      #                    resolved per check against application settings.
      #                    Omitted for entries whose threshold arrives per call
      #                    (see threshold_from_caller and cost_mode below).
      #   period:          window as an Integer (seconds), an ActiveSupport
      #                    duration, or a callable. Omitted for cost_mode entries
      #                    (the interval arrives per call).
      #   action:          forwarded to the labkit Rule; the adapter
      #                    returns labkit's boolean decision to the caller.
      #
      # `web_hook_calls{,_low,_mid}` receive their threshold per call from
      # PlanLimits and so omit `limit:` (it resolves to 0, matching the legacy
      # hash, which carried no threshold for them); the adapter forwards the
      # caller's value via rule_context rather than treating it as an override.
      module SupportedRateLimits
        def self.all
          @all ||= limiters.freeze
        end

        def self.rules
          @rules ||= rule_definitions.freeze
        end

        def self.limiter_for(key)
          all.fetch(key)
        end

        def self.rule_for(key)
          rules.fetch(key)
        end

        def self.limit_for(key, context: nil)
          resolve_value(rule_for(key).limit, context)
        end

        def self.period_for(key, context: nil)
          resolve_value(rule_for(key).period, context)
        end

        def self.cost_mode?(key)
          cost_mode_keys.include?(key)
        end

        # Mirrors labkit's own Evaluator#resolve_value contract (see
        # gitlab-labkit's lib/labkit/rate_limit/evaluator.rb) so that the
        # values we resolve here match what labkit will actually enforce.
        # Variadic callables (negative arity, e.g. ->(*ctx) { ... }) are
        # intentionally excluded, not by oversight: labkit only forwards
        # rule_context to callables with exactly one required parameter
        # (->(ctx) { ... }); passing it to a splat would wrap it in an
        # array (args == [rule_context]) instead of binding it directly,
        # which is a worse footgun. Keep this check in lockstep with
        # labkit's arity >= 1 condition rather than "fixing" it to accept
        # variadic callables.
        def self.accepts_context?(value)
          value.respond_to?(:call) && value.respond_to?(:arity) && value.arity >= 1
        end

        def self.rule_definitions # rubocop:disable Metrics/AbcSize, -- static registry of rate-limit definitions
          {
            ai_action: ::Labkit::RateLimit::Rule.new(
              name: 'limit_ai_actions_by_user',
              characteristics: %i[user],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.ai_action_api_rate_limit },
              period: 8.hours,
              action: :limit
            ),
            auto_rollback_deployment: ::Labkit::RateLimit::Rule.new(
              name: 'limit_auto_rollbacks_by_environment',
              characteristics: %i[environment],
              limit: 1,
              period: 3.minutes,
              action: :limit
            ),
            autocomplete_users: ::Labkit::RateLimit::Rule.new(
              name: 'limit_user_autocompletes_by_user',
              characteristics: %i[user],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.autocomplete_users_limit },
              period: 1.minute,
              action: :limit
            ),
            autocomplete_users_unauthenticated: ::Labkit::RateLimit::Rule.new(
              name: 'limit_user_autocompletes_by_ip',
              characteristics: %i[ip],
              limit: -> {
                Gitlab::CurrentSettings.current_application_settings.autocomplete_users_unauthenticated_limit
              },
              period: 1.minute,
              action: :limit
            ),
            bitbucket_server_import: ::Labkit::RateLimit::Rule.new(
              name: 'limit_bitbucket_server_imports_by_user',
              characteristics: %i[user],
              limit: 6,
              period: 1.minute,
              action: :limit
            ),
            bulk_delete_todos: ::Labkit::RateLimit::Rule.new(
              name: 'limit_bulk_todo_deletes_by_user',
              characteristics: %i[user],
              limit: 6,
              period: 1.minute,
              action: :limit
            ),
            bulk_import: ::Labkit::RateLimit::Rule.new(
              name: 'limit_bulk_imports_by_user',
              characteristics: %i[user],
              limit: 6,
              period: 1.minute,
              action: :limit
            ),
            ci_job_processed_subscription: ::Labkit::RateLimit::Rule.new(
              name: 'limit_ci_job_processed_subscriptions_by_project',
              characteristics: %i[project],
              limit: 50,
              period: 1.minute,
              action: :limit
            ),
            ci_lint: ::Labkit::RateLimit::Rule.new(
              name: 'limit_ci_lint_by_user',
              characteristics: %i[user],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.ci_lint_limit_per_user },
              period: 1.minute,
              action: :limit
            ),
            ci_pipeline_statuses_subscription: ::Labkit::RateLimit::Rule.new(
              name: 'limit_ci_pipeline_status_subscriptions_by_project',
              characteristics: %i[project],
              limit: 50,
              period: 1.minute,
              action: :limit
            ),
            code_suggestions_api_endpoint: ::Labkit::RateLimit::Rule.new(
              name: 'limit_code_suggestions_by_user',
              characteristics: %i[user],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.code_suggestions_api_rate_limit },
              period: 1.minute,
              action: :limit
            ),
            create_organization_api: ::Labkit::RateLimit::Rule.new(
              name: 'limit_organization_creates_by_user',
              characteristics: %i[user],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.create_organization_api_limit },
              period: 1.minute,
              action: :limit
            ),
            delete_all_todos: ::Labkit::RateLimit::Rule.new(
              name: 'limit_todo_bulk_deletes_by_user',
              characteristics: %i[user],
              limit: 1,
              period: 5.minutes,
              action: :limit
            ),
            deployment_delete: ::Labkit::RateLimit::Rule.new(
              name: 'limit_deployment_deletes_by_user',
              characteristics: %i[user],
              limit: 500,
              period: 1.minute,
              action: :limit
            ),
            downstream_pipeline_trigger: ::Labkit::RateLimit::Rule.new(
              name: 'limit_downstream_pipeline_triggers_by_project_user_sha',
              characteristics: %i[project user sha],
              limit: -> {
                Gitlab::CurrentSettings.current_application_settings.downstream_pipeline_trigger_limit_per_project_user_sha
              },
              period: 1.minute,
              action: :limit
            ),
            email_verification: ::Labkit::RateLimit::Rule.new(
              name: 'limit_email_verifies_by_subject',
              characteristics: %i[subject],
              limit: 10,
              period: 10.minutes,
              action: :limit
            ),
            email_verification_code_send: ::Labkit::RateLimit::Rule.new(
              name: 'limit_email_verification_sends_by_user',
              characteristics: %i[user],
              limit: 10,
              period: 1.hour,
              action: :limit
            ),
            expanded_diff_files: ::Labkit::RateLimit::Rule.new(
              name: 'limit_expanded_diff_files_by_user_or_ip',
              characteristics: %i[user ip],
              limit: 6,
              period: 1.minute,
              action: :limit
            ),
            feature_library_search: ::Labkit::RateLimit::Rule.new(
              name: 'limit_feature_library_searches_by_user',
              characteristics: %i[user],
              limit: 60,
              period: 1.minute,
              action: :limit
            ),
            feature_library_ai_search: ::Labkit::RateLimit::Rule.new(
              name: 'limit_feature_library_ai_searches_by_user',
              characteristics: %i[user],
              limit: 10,
              period: 1.minute,
              action: :limit
            ),
            fetch_google_ip_list: ::Labkit::RateLimit::Rule.new(
              name: 'limit_google_ip_list_fetches_by_scope',
              characteristics: %i[scope],
              limit: 10,
              period: 1.minute,
              action: :limit
            ),
            fogbugz_import: ::Labkit::RateLimit::Rule.new(
              name: 'limit_fogbugz_imports_by_user',
              characteristics: %i[user],
              limit: 1,
              period: 1.minute,
              action: :limit
            ),
            geo_proxy: ::Labkit::RateLimit::Rule.new(
              name: 'limit_geo_proxy_requests_by_ip',
              characteristics: %i[ip],
              limit: 60,
              period: 1.minute,
              action: :limit
            ),
            gitea_import: ::Labkit::RateLimit::Rule.new(
              name: 'limit_gitea_imports_by_user',
              characteristics: %i[user],
              limit: 6,
              period: 1.minute,
              action: :limit
            ),
            github_import: ::Labkit::RateLimit::Rule.new(
              name: 'limit_github_imports_by_user',
              characteristics: %i[user],
              limit: 6,
              period: 1.minute,
              action: :limit
            ),
            gitlab_shell_operation: ::Labkit::RateLimit::Rule.new(
              name: 'limit_gitlab_shell_operations_by_action_project_actor',
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
              action: :limit
            ),
            glql: ::Labkit::RateLimit::Rule.new(
              name: 'limit_glql_queries_by_query_sha',
              characteristics: %i[query_sha],
              limit: 1,
              period: 15.minutes,
              action: :limit
            ),
            group_api: ::Labkit::RateLimit::Rule.new(
              name: 'limit_group_api_by_user_or_ip',
              characteristics: %i[user ip],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.group_api_limit },
              period: 1.minute,
              action: :limit
            ),
            group_archive_unarchive_api: ::Labkit::RateLimit::Rule.new(
              name: 'limit_group_archive_unarchive_api_by_user_or_ip',
              characteristics: %i[user ip],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.group_archive_unarchive_api_limit },
              period: 1.minute,
              action: :limit
            ),
            group_download_export: ::Labkit::RateLimit::Rule.new(
              name: 'limit_group_export_downloads_by_user_group',
              characteristics: %i[user group],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.group_download_export_limit },
              period: 1.minute,
              action: :limit
            ),
            group_export: ::Labkit::RateLimit::Rule.new(
              name: 'limit_group_exports_by_user',
              characteristics: %i[user],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.group_export_limit },
              period: 1.minute,
              action: :limit
            ),
            group_import: ::Labkit::RateLimit::Rule.new(
              name: 'limit_group_imports_by_user',
              characteristics: %i[user],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.group_import_limit },
              period: 1.minute,
              action: :limit
            ),
            group_invited_groups_api: ::Labkit::RateLimit::Rule.new(
              name: 'limit_group_invited_groups_api_by_user_or_ip',
              characteristics: %i[user ip],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.group_invited_groups_api_limit },
              period: 1.minute,
              action: :limit
            ),
            group_projects_api: ::Labkit::RateLimit::Rule.new(
              name: 'limit_group_projects_api_by_user_or_ip',
              characteristics: %i[user ip],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.group_projects_api_limit },
              period: 1.minute,
              action: :limit
            ),
            group_shared_groups_api: ::Labkit::RateLimit::Rule.new(
              name: 'limit_group_shared_groups_api_by_user_or_ip',
              characteristics: %i[user ip],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.group_shared_groups_api_limit },
              period: 1.minute,
              action: :limit
            ),
            groups_api: ::Labkit::RateLimit::Rule.new(
              name: 'limit_groups_api_by_user_or_ip',
              characteristics: %i[user ip],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.groups_api_limit },
              period: 1.minute,
              action: :limit
            ),
            groups_create: ::Labkit::RateLimit::Rule.new(
              name: 'limit_groups_created_by_user',
              characteristics: %i[user],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.group_create_limit },
              period: 1.day,
              action: :limit
            ),
            import_source_user_notification: ::Labkit::RateLimit::Rule.new(
              name: 'limit_import_source_user_notifications_by_source_user',
              characteristics: %i[import_source_user],
              limit: 1,
              period: 8.hours,
              action: :limit
            ),
            issues_create: ::Labkit::RateLimit::Rule.new(
              name: 'limit_issues_by_project_user_external_author',
              characteristics: %i[project user external_author],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.issues_create_limit },
              period: 1.minute,
              action: :limit
            ),
            jobs_index: ::Labkit::RateLimit::Rule.new(
              name: 'limit_jobs_index_by_user',
              characteristics: %i[user],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.project_jobs_api_rate_limit },
              period: 1.minute,
              action: :limit
            ),
            large_blob_download: ::Labkit::RateLimit::Rule.new(
              name: 'limit_large_blob_downloads_by_project',
              characteristics: %i[project],
              limit: 5,
              period: 1.minute,
              action: :limit
            ),
            members_delete: ::Labkit::RateLimit::Rule.new(
              name: 'limit_member_deletes_by_source_user',
              characteristics: %i[project group user],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.members_delete_limit },
              period: 1.minute,
              action: :limit
            ),
            mobile_push_notifications: ::Labkit::RateLimit::Rule.new(
              name: 'limit_mobile_push_notifications_by_user',
              characteristics: %i[user],
              limit: 60,
              period: 1.hour,
              action: :limit
            ),
            namespace_exists: ::Labkit::RateLimit::Rule.new(
              name: 'limit_namespace_existence_checks_by_user',
              characteristics: %i[user],
              limit: 20,
              period: 1.minute,
              action: :limit
            ),
            namespace_work_item_changes_broadcast: ::Labkit::RateLimit::Rule.new(
              name: 'limit_namespace_work_item_change_broadcasts_by_namespace',
              characteristics: %i[group namespace],
              limit: 30,
              period: 1.minute,
              action: :limit
            ),
            notes_create: ::Labkit::RateLimit::Rule.new(
              name: 'limit_notes_by_user',
              characteristics: %i[user],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.notes_create_limit },
              period: 1.minute,
              action: :limit
            ),
            notification_emails: ::Labkit::RateLimit::Rule.new(
              name: 'limit_notification_emails_by_parent_user',
              characteristics: %i[project group user],
              limit: 1000,
              period: 1.day,
              action: :limit
            ),
            oauth_dynamic_registration: ::Labkit::RateLimit::Rule.new(
              name: 'limit_oauth_registrations_by_ip',
              characteristics: %i[ip],
              limit: 10,
              period: 1.hour,
              action: :limit
            ),
            observability_bff_session: ::Labkit::RateLimit::Rule.new(
              name: 'limit_observability_bff_sessions_by_user',
              characteristics: %i[user],
              limit: 20,
              period: 1.minute,
              action: :limit
            ),
            offline_export: ::Labkit::RateLimit::Rule.new(
              name: 'limit_offline_exports_by_user',
              characteristics: %i[user],
              limit: 6,
              period: 1.minute,
              action: :limit
            ),
            offline_import: ::Labkit::RateLimit::Rule.new(
              name: 'limit_offline_imports_by_user',
              characteristics: %i[user],
              limit: 6,
              period: 1.minute,
              action: :limit
            ),
            organization_user_create: ::Labkit::RateLimit::Rule.new(
              name: 'limit_organization_user_creates_by_user',
              characteristics: %i[user],
              limit: 20,
              period: 1.minute,
              action: :limit
            ),
            permanent_email_failure: ::Labkit::RateLimit::Rule.new(
              name: 'limit_permanent_email_failures_by_email',
              characteristics: %i[email],
              limit: 5,
              period: 1.day,
              action: :limit
            ),
            phone_verification_send_code: ::Labkit::RateLimit::Rule.new(
              name: 'limit_phone_verification_sends_by_user',
              characteristics: %i[user],
              limit: 5,
              period: 1.day,
              action: :limit
            ),
            phone_verification_verify_code: ::Labkit::RateLimit::Rule.new(
              name: 'limit_phone_verification_verifies_by_user',
              characteristics: %i[user],
              limit: 5,
              period: 1.day,
              action: :limit
            ),
            pipelines_create: ::Labkit::RateLimit::Rule.new(
              name: 'limit_pipelines_by_project_user_sha',
              characteristics: %i[project user sha],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.pipeline_limit_per_project_user_sha },
              period: 1.minute,
              action: :limit
            ),
            pipelines_created_per_user: ::Labkit::RateLimit::Rule.new(
              name: 'limit_pipelines_by_user',
              characteristics: %i[user],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.pipeline_limit_per_user },
              period: 1.minute,
              action: :limit
            ),
            placeholder_reassignment: ::Labkit::RateLimit::Rule.new(
              name: 'limit_placeholder_reassignments_by_user',
              characteristics: %i[user],
              limit: 5,
              period: 1.minute,
              action: :limit
            ),
            play_pipeline_schedule: ::Labkit::RateLimit::Rule.new(
              name: 'limit_pipeline_schedule_plays_by_user_schedule',
              characteristics: %i[user ci_pipeline_schedule],
              limit: 1,
              period: 1.minute,
              action: :limit
            ),
            profile_add_new_email: ::Labkit::RateLimit::Rule.new(
              name: 'limit_profile_email_adds_by_user',
              characteristics: %i[user],
              limit: 5,
              period: 1.minute,
              action: :limit
            ),
            profile_resend_email_confirmation: ::Labkit::RateLimit::Rule.new(
              name: 'limit_profile_email_confirm_resends_by_user',
              characteristics: %i[user],
              limit: 5,
              period: 1.minute,
              action: :limit
            ),
            profile_update_username: ::Labkit::RateLimit::Rule.new(
              name: 'limit_profile_username_updates_by_user',
              characteristics: %i[user],
              limit: 10,
              period: 1.minute,
              action: :limit
            ),
            project_api: ::Labkit::RateLimit::Rule.new(
              name: 'limit_project_api_by_user_or_ip',
              characteristics: %i[user ip],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.project_api_limit },
              period: 1.minute,
              action: :limit
            ),
            project_download_export: ::Labkit::RateLimit::Rule.new(
              name: 'limit_project_export_downloads_by_user_project',
              characteristics: %i[user project],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.project_download_export_limit },
              period: 1.minute,
              action: :limit
            ),
            project_export: ::Labkit::RateLimit::Rule.new(
              name: 'limit_project_exports_by_user',
              characteristics: %i[user],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.project_export_limit },
              period: 1.minute,
              action: :limit
            ),
            project_fork_sync: ::Labkit::RateLimit::Rule.new(
              name: 'limit_project_fork_syncs_by_project_user',
              characteristics: %i[project user],
              limit: 10,
              period: 30.minutes,
              action: :limit
            ),
            project_generate_new_export: ::Labkit::RateLimit::Rule.new(
              name: 'limit_project_export_generations_by_user',
              characteristics: %i[user],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.project_export_limit },
              period: 1.minute,
              action: :limit
            ),
            project_import: ::Labkit::RateLimit::Rule.new(
              name: 'limit_project_imports_by_user_action',
              characteristics: %i[user action],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.project_import_limit },
              period: 1.minute,
              action: :limit
            ),
            project_invited_groups_api: ::Labkit::RateLimit::Rule.new(
              name: 'limit_project_invited_groups_api_by_user_or_ip',
              characteristics: %i[user ip],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.project_invited_groups_api_limit },
              period: 1.minute,
              action: :limit
            ),
            project_members_api: ::Labkit::RateLimit::Rule.new(
              name: 'limit_project_members_api_by_user_or_ip',
              characteristics: %i[user ip],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.project_members_api_limit },
              period: 1.minute,
              action: :limit
            ),
            project_repositories_archive: ::Labkit::RateLimit::Rule.new(
              name: 'limit_project_repository_archives_by_project_user',
              characteristics: %i[project user],
              limit: ->(ctx) { ctx&.dig(:threshold) || 5 },
              period: 1.minute,
              action: :limit
            ),
            project_repositories_blobs_batch: ::Labkit::RateLimit::Rule.new(
              name: 'limit_project_repository_blobs_batch_by_project_user',
              characteristics: %i[project user],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.project_repositories_blobs_batch_limit },
              period: 1.minute,
              action: :limit
            ),
            project_repositories_changelog: ::Labkit::RateLimit::Rule.new(
              name: 'limit_project_repository_changelogs_by_user_project',
              characteristics: %i[user project],
              limit: 5,
              period: 1.minute,
              action: :limit
            ),
            project_repositories_diff_stats: ::Labkit::RateLimit::Rule.new(
              name: 'limit_project_repository_diff_stats_by_user_project',
              characteristics: %i[user project],
              limit: 30,
              period: 1.minute,
              action: :limit
            ),
            project_repositories_diverging_commits: ::Labkit::RateLimit::Rule.new(
              name: 'limit_project_repository_diverging_commits_by_user_project',
              characteristics: %i[user project],
              limit: 30,
              period: 1.minute,
              action: :limit
            ),
            project_repositories_health: ::Labkit::RateLimit::Rule.new(
              name: 'limit_project_repository_health_by_project',
              characteristics: %i[project],
              limit: 5,
              period: 1.hour,
              action: :limit
            ),
            project_testing_integration: ::Labkit::RateLimit::Rule.new(
              name: 'limit_integration_tests_by_project_user',
              characteristics: %i[project user],
              limit: 5,
              period: 1.minute,
              action: :limit
            ),
            projects_api: ::Labkit::RateLimit::Rule.new(
              name: 'limit_projects_api_by_user_or_ip',
              characteristics: %i[user ip],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.projects_api_limit },
              period: 10.minutes,
              action: :limit
            ),
            projects_api_rate_limit_unauthenticated: ::Labkit::RateLimit::Rule.new(
              name: 'limit_projects_api_by_ip',
              characteristics: %i[ip],
              limit: -> {
                Gitlab::CurrentSettings.current_application_settings.projects_api_rate_limit_unauthenticated
              },
              period: 10.minutes,
              action: :limit
            ),
            projects_create: ::Labkit::RateLimit::Rule.new(
              name: 'limit_projects_created_by_user',
              characteristics: %i[user],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.project_create_limit },
              period: 1.day,
              action: :limit
            ),
            raw_blob: ::Labkit::RateLimit::Rule.new(
              name: 'limit_raw_blobs_by_project_path',
              characteristics: %i[project path],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.raw_blob_request_limit },
              period: 1.minute,
              action: :limit
            ),
            raw_blob_unauthenticated: ::Labkit::RateLimit::Rule.new(
              name: 'limit_raw_blobs_by_project',
              characteristics: %i[project],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.raw_blob_request_limit_unauthenticated },
              period: 1.minute,
              action: :limit
            ),
            runner_jobs_api: ::Labkit::RateLimit::Rule.new(
              name: 'limit_runner_jobs_by_job_token',
              characteristics: %i[job_token_sha],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.runner_jobs_endpoints_api_limit },
              period: 1.minute,
              action: :limit
            ),
            runner_jobs_patch_trace_api: ::Labkit::RateLimit::Rule.new(
              name: 'limit_runner_job_traces_by_job_token',
              characteristics: %i[job_token_sha],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.runner_jobs_patch_trace_api_limit },
              period: 1.minute,
              action: :limit
            ),
            runner_jobs_request_api: ::Labkit::RateLimit::Rule.new(
              name: 'limit_runner_job_requests_by_runner_token',
              characteristics: %i[runner_token_sha],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.runner_jobs_request_api_limit },
              period: 1.minute,
              action: :limit
            ),
            search_index_integrity: ::Labkit::RateLimit::Rule.new(
              name: 'limit_search_index_integrity_checks_by_project_or_group',
              characteristics: %i[project group],
              limit: 1,
              period: 30.minutes,
              action: :limit
            ),
            search_rate_limit: ::Labkit::RateLimit::Rule.new(
              name: 'limit_searches_by_user_scope',
              characteristics: %i[user search_scope],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.search_rate_limit },
              period: 1.minute,
              action: :limit
            ),
            search_rate_limit_unauthenticated: ::Labkit::RateLimit::Rule.new(
              name: 'limit_searches_by_ip',
              characteristics: %i[ip],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.search_rate_limit_unauthenticated },
              period: 1.minute,
              action: :limit
            ),
            service_account_creation: ::Labkit::RateLimit::Rule.new(
              name: 'limit_service_account_creates_by_user',
              characteristics: %i[user],
              limit: 10,
              period: 1.minute,
              action: :limit
            ),
            temporary_email_failure: ::Labkit::RateLimit::Rule.new(
              name: 'limit_temporary_email_failures_by_email',
              characteristics: %i[email],
              limit: 300,
              period: 1.day,
              action: :limit
            ),
            token_exchange: ::Labkit::RateLimit::Rule.new(
              name: 'limit_token_exchanges_by_user',
              characteristics: %i[user],
              limit: 60,
              period: 1.minute,
              action: :limit
            ),
            update_environment_canary_ingress: ::Labkit::RateLimit::Rule.new(
              name: 'limit_canary_ingress_updates_by_environment',
              characteristics: %i[environment],
              limit: 1,
              period: 1.minute,
              action: :limit
            ),
            update_namespace_name: ::Labkit::RateLimit::Rule.new(
              name: 'limit_namespace_name_updates_by_namespace',
              characteristics: %i[namespace],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.update_namespace_name_rate_limit },
              period: 1.hour,
              action: :limit
            ),
            user_contributed_projects_api: ::Labkit::RateLimit::Rule.new(
              name: 'limit_user_contributed_projects_api_by_user_or_ip',
              characteristics: %i[user ip],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.user_contributed_projects_api_limit },
              period: 1.minute,
              action: :limit
            ),
            user_followers: ::Labkit::RateLimit::Rule.new(
              name: 'limit_user_followers_api_by_user_or_ip',
              characteristics: %i[user ip],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.users_api_limit_followers },
              period: 1.minute,
              action: :limit
            ),
            user_following: ::Labkit::RateLimit::Rule.new(
              name: 'limit_user_following_api_by_user_or_ip',
              characteristics: %i[user ip],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.users_api_limit_following },
              period: 1.minute,
              action: :limit
            ),
            user_gpg_key: ::Labkit::RateLimit::Rule.new(
              name: 'limit_user_gpg_key_api_by_user_or_ip',
              characteristics: %i[user ip],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.users_api_limit_gpg_key },
              period: 1.minute,
              action: :limit
            ),
            user_gpg_keys: ::Labkit::RateLimit::Rule.new(
              name: 'limit_user_gpg_keys_api_by_user_or_ip',
              characteristics: %i[user ip],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.users_api_limit_gpg_keys },
              period: 1.minute,
              action: :limit
            ),
            user_large_commit_request: ::Labkit::RateLimit::Rule.new(
              name: 'limit_large_commit_requests_by_user',
              characteristics: %i[user],
              limit: 3,
              period: 30.seconds,
              action: :limit
            ),
            user_projects_api: ::Labkit::RateLimit::Rule.new(
              name: 'limit_user_projects_api_by_user_or_ip',
              characteristics: %i[user ip],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.user_projects_api_limit },
              period: 1.minute,
              action: :limit
            ),
            user_sign_in: ::Labkit::RateLimit::Rule.new(
              name: 'limit_signins_by_user',
              characteristics: %i[user],
              limit: 5,
              period: 10.minutes,
              action: :limit
            ),
            user_sign_up: ::Labkit::RateLimit::Rule.new(
              name: 'limit_signups_by_ip',
              characteristics: %i[ip],
              limit: 20,
              period: 1.minute,
              action: :limit
            ),
            user_ssh_key: ::Labkit::RateLimit::Rule.new(
              name: 'limit_user_ssh_key_api_by_user_or_ip',
              characteristics: %i[user ip],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.users_api_limit_ssh_key },
              period: 1.minute,
              action: :limit
            ),
            user_ssh_keys: ::Labkit::RateLimit::Rule.new(
              name: 'limit_user_ssh_keys_api_by_user_or_ip',
              characteristics: %i[user ip],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.users_api_limit_ssh_keys },
              period: 1.minute,
              action: :limit
            ),
            user_starred_projects_api: ::Labkit::RateLimit::Rule.new(
              name: 'limit_user_starred_projects_api_by_user_or_ip',
              characteristics: %i[user ip],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.user_starred_projects_api_limit },
              period: 1.minute,
              action: :limit
            ),
            user_status: ::Labkit::RateLimit::Rule.new(
              name: 'limit_user_status_api_by_user_or_ip',
              characteristics: %i[user ip],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.users_api_limit_status },
              period: 1.minute,
              action: :limit
            ),
            username_exists: ::Labkit::RateLimit::Rule.new(
              name: 'limit_username_existence_checks_by_ip',
              characteristics: %i[ip],
              limit: 20,
              period: 1.minute,
              action: :limit
            ),
            users_get_by_id: ::Labkit::RateLimit::Rule.new(
              name: 'limit_user_lookups_by_user',
              characteristics: %i[user],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.users_get_by_id_limit },
              period: 10.minutes,
              action: :limit
            ),
            # web_hook_calls{,_low,_mid} carry no static threshold: the limit
            # is looked up per namespace from PlanLimits and passed in via the
            # caller's `threshold:` argument. They therefore omit `limit:` (it
            # resolves to 0, exactly as the legacy hash did, which carried no
            # threshold for them). `threshold_from_caller: true` opts the entry
            # out of the adapter's threshold-override bail so the caller's value
            # is forwarded through to labkit's one-arity limit callable via
            # rule_context. The `1.minute` period is the registry value and is
            # not caller-controlled.
            web_hook_calls: ::Labkit::RateLimit::Rule.new(
              name: 'limit_web_hook_calls_by_namespace',
              characteristics: %i[namespace],
              limit: ->(ctx) { ctx&.dig(:threshold) || 0 },
              period: 1.minute,
              action: :limit
            ),
            web_hook_calls_low: ::Labkit::RateLimit::Rule.new(
              name: 'limit_web_hook_calls_low_by_namespace',
              characteristics: %i[namespace],
              limit: ->(ctx) { ctx&.dig(:threshold) || 0 },
              period: 1.minute,
              action: :limit
            ),
            web_hook_calls_mid: ::Labkit::RateLimit::Rule.new(
              name: 'limit_web_hook_calls_mid_by_namespace',
              characteristics: %i[namespace],
              limit: ->(ctx) { ctx&.dig(:threshold) || 0 },
              period: 1.minute,
              action: :limit
            ),
            web_hook_event_resend: ::Labkit::RateLimit::Rule.new(
              name: 'limit_web_hook_event_resends_by_parent_user',
              characteristics: %i[project group user],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.web_hook_event_resend_limit },
              period: 1.minute,
              action: :limit
            ),
            web_hook_test: ::Labkit::RateLimit::Rule.new(
              name: 'limit_web_hook_tests_by_parent_user',
              characteristics: %i[project group user],
              limit: -> { Gitlab::CurrentSettings.current_application_settings.web_hook_test_limit },
              period: 1.minute,
              action: :limit
            ),
            # Per-database Sidekiq resource-usage (DB duration) limits,
            # one Limiter per database. Cost-mode (the per-job DB duration is the
            # `check(cost:)` value, not a call count). threshold and interval are
            # both caller-supplied: SidekiqLimits.limits_for resolves the worker's
            # urgency rule and any ApplicationSetting override upstream, so the
            # labkit Rule must use that resolved value (not a static constant).
            # They therefore carry no static limit/period; both arrive per call
            # via rule_context and these keys are absent from rate_limits.
            main_db_duration_limit_per_worker: ::Labkit::RateLimit::Rule.new(
              name: 'limit_main_db_duration_per_worker',
              characteristics: %i[worker_name],
              limit: ->(ctx) { ctx&.dig(:threshold) || 0 },
              period: ->(ctx) { ctx&.dig(:interval) || 0 },
              action: :limit
            ),
            ci_db_duration_limit_per_worker: ::Labkit::RateLimit::Rule.new(
              name: 'limit_ci_db_duration_per_worker',
              characteristics: %i[worker_name],
              limit: ->(ctx) { ctx&.dig(:threshold) || 0 },
              period: ->(ctx) { ctx&.dig(:interval) || 0 },
              action: :limit
            ),
            sec_db_duration_limit_per_worker: ::Labkit::RateLimit::Rule.new(
              name: 'limit_sec_db_duration_per_worker',
              characteristics: %i[worker_name],
              limit: ->(ctx) { ctx&.dig(:threshold) || 0 },
              period: ->(ctx) { ctx&.dig(:interval) || 0 },
              action: :limit
            )
          }
        end

        def self.limiters
          rules.keys.index_with { |key| build_limiter(key) }
        end

        def self.build_limiter(key)
          ::Labkit::RateLimit::Limiter.new(
            name: "applimiter_#{key}",
            rules: [bypass_rule_for(key), rule_for(key)],
            redis: ::Gitlab::Redis::RateLimiting,
            logger: ::Gitlab::AppLogger
          )
        end
        private_class_method :build_limiter

        # A synthetic :skip rule ahead of the real throttle rule: bypass-header
        # traffic (identifier[:bypass_header] == '1') terminates here before
        # touching Redis, so it stays visible via calls_total{action="skip"}
        # without back-filling the real rule's rate. Named per key so each
        # limit's bypass volume is distinguishable in Prometheus/Grafana.
        def self.bypass_rule_for(key)
          ::Labkit::RateLimit::Rule.new(
            name: "#{key}_bypass",
            match: { bypass_header: ::Gitlab::Throttle::BYPASS_HEADER_VALUE },
            characteristics: [],
            limit: 0, # unused: action: :skip terminates evaluation before limit/period are consulted
            period: 60, # unused: action: :skip terminates evaluation before limit/period are consulted
            action: :skip
          )
        end
        private_class_method :bypass_rule_for

        def self.cost_mode_keys
          Set.new([:main_db_duration_limit_per_worker, :ci_db_duration_limit_per_worker,
            :sec_db_duration_limit_per_worker]).freeze
        end
        private_class_method :cost_mode_keys

        def self.resolve_value(value, context)
          return value.to_i unless value.respond_to?(:call)

          value = accepts_context?(value) ? value.call(context) : value.call
          value.to_i
        end
        private_class_method :resolve_value
      end
    end
  end
end

Gitlab::ApplicationRateLimiter::LabkitAdapter::SupportedRateLimits.prepend_mod
