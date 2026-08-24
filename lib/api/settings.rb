# frozen_string_literal: true

module API
  class Settings < ::API::Base
    before { authenticated_as_admin! }

    feature_category :not_owned # rubocop:todo Gitlab/AvoidFeatureCategoryNotOwned

    helpers Helpers::SettingsHelpers

    helpers do
      def current_settings
        @current_setting ||= ApplicationSetting.find_or_create_without_cache
      end

      def filter_attributes_using_license(attrs)
        # This method will be redefined in EE.
        attrs
      end
    end

    desc 'Retrieve application settings' do
      detail 'Retrieves the current application settings for this GitLab instance.'
      tags ['instance']
      success Entities::ApplicationSetting
      failure [
        { code: 401, message: 'Unauthorized' },
        { code: 403, message: 'Forbidden' }
      ]
    end
    route_setting :authorization, permissions: :read_application_setting, boundary_type: :instance
    get "application/settings" do
      present current_settings, with: Entities::ApplicationSetting
    end

    desc 'Update application settings' do
      detail 'Updates the current application settings for this GitLab instance.'
      tags ['instance']
      success Entities::ApplicationSetting
      failure [
        { code: 401, message: 'Unauthorized' },
        { code: 403, message: 'Forbidden' }
      ]
    end
    params do
      optional :admin_mode, type: Boolean, desc: 'Require admin users to re-authenticate for administrative (i.e. potentially dangerous) operations'
      optional :admin_notification_email, type: String, desc: 'Deprecated: Use :abuse_notification_email instead. Abuse reports will be sent to this address if it is set. Abuse reports are always available in the admin area.'
      optional :abuse_notification_email, type: String, desc: 'Abuse reports will be sent to this address if it is set. Abuse reports are always available in the admin area.'
      optional :after_sign_up_text, type: String, desc: 'Text shown after sign up'
      optional :after_sign_out_path, type: String, desc: 'We will redirect users to this page after they sign out'
      optional :akismet_enabled, type: Boolean, desc: 'Helps prevent bots from creating issues'
      given akismet_enabled: ->(val) { val } do
        requires :akismet_api_key, type: String, desc: 'Generate API key at http://www.akismet.com'
      end
      optional :asset_proxy_enabled, type: Boolean, desc: 'Enable proxying of assets'
      optional :asset_proxy_url, type: String, desc: 'URL of the asset proxy server'
      optional :asset_proxy_secret_key, type: String, desc: 'Shared secret with the asset proxy server'
      optional :asset_proxy_whitelist, type: Array[String], coerce_with: Validations::Types::CommaSeparatedToArray.coerce, desc: 'Deprecated: Use :asset_proxy_allowlist instead. Assets that match these domain(s) will NOT be proxied. Wildcards allowed. Your GitLab installation URL is automatically whitelisted.'
      optional :asset_proxy_allowlist, type: Array[String], coerce_with: Validations::Types::CommaSeparatedToArray.coerce, desc: 'Assets that match these domain(s) will NOT be proxied. Wildcards allowed. Your GitLab installation URL is automatically allowed.'
      optional :authn_data_retention_cleanup_enabled, type: Boolean, desc: 'Enable authentication data retention cleanup workers to enforce retention policies'
      optional :container_registry_token_expire_delay, type: Integer, desc: 'Authorization token duration (minutes)'
      optional :oauth_access_token_expires_in, type: Integer, desc: 'Lifetime of OAuth access tokens in seconds.'
      optional :decompress_archive_file_timeout, type: Integer, desc: 'Default timeout for decompressing archived files, in seconds. Set to 0 to disable timeouts.'
      optional :default_artifacts_expire_in, type: String, desc: "Set the default expiration time for each job's artifacts"
      optional :default_ci_config_path, type: String, desc: 'The instance default CI/CD configuration file and path for new projects'
      optional :default_project_creation, type: Integer, values: ::Gitlab::Access.project_creation_values, desc: 'Determine if developers can create projects in the group'
      optional :default_branch_protection, type: Integer, values: ::Gitlab::Access.protection_values, desc: 'Determine if developers can push to default branch'
      optional :default_branch_protection_defaults, type: Hash, desc: 'Determine if developers can push to default branch' do
        optional :allowed_to_push, type: Array, desc: 'An array of access levels allowed to push' do
          # rubocop:disable API/AccessLevelStringType -- Introduced before the cop
          requires :access_level, type: Integer, values: ProtectedBranch::PushAccessLevel.allowed_access_levels, desc: 'A valid access level'
          # rubocop:enable API/AccessLevelStringType
        end
        optional :allow_force_push, type: Boolean, desc: 'Allow force push for all users with push access.'
        optional :allowed_to_merge, type: Array, desc: 'An array of access levels allowed to merge' do
          # rubocop:disable API/AccessLevelStringType -- Introduced before the cop
          requires :access_level, type: Integer, values: ProtectedBranch::MergeAccessLevel.allowed_access_levels, desc: 'A valid access level'
          # rubocop:enable API/AccessLevelStringType
        end
        optional :code_owner_approval_required, type: Boolean, desc: "Require approval from code owners"
        optional :developer_can_initial_push, type: Boolean, desc: 'Allow developers to initial push'
      end
      optional :default_group_visibility, type: String, values: Gitlab::VisibilityLevel.string_values, desc: 'The default group visibility'
      optional :default_project_visibility, type: String, values: Gitlab::VisibilityLevel.string_values, desc: 'The default project visibility'
      optional :default_projects_limit, type: Integer, desc: 'The maximum number of personal projects'
      optional :default_snippet_visibility, type: String, values: Gitlab::VisibilityLevel.string_values, desc: 'The default snippet visibility'
      optional :dependency_management_settings, type: Hash, desc: 'Dependency management settings' do
        optional :security_update_scheduler_max_concurrency, type: Integer, desc: 'Maximum number of dependency management security update scheduler jobs that run concurrently across the Sidekiq fleet'
      end
      optional :disable_admin_oauth_scopes, type: Boolean, desc: 'Stop administrators from connecting to non-trusted OAuth applications.'
      optional :disable_feed_token, type: Boolean, desc: 'Disable display of RSS/Atom and Calendar `feed_tokens`'
      optional :disabled_oauth_sign_in_sources, type: Array[String], coerce_with: Validations::Types::CommaSeparatedToArray.coerce, desc: 'Disable certain OAuth sign-in sources'
      optional :domain_denylist_enabled, type: Boolean, desc: 'Enable domain denylist for sign ups'
      optional :domain_denylist, type: Array[String], coerce_with: Validations::Types::CommaSeparatedToArray.coerce, desc: 'Users with e-mail addresses that match these domain(s) will NOT be able to sign-up. Wildcards allowed. Enter multiple entries on separate lines. Ex: domain.com, *.domain.com'
      optional :domain_allowlist, type: Array[String], coerce_with: Validations::Types::CommaSeparatedToArray.coerce, desc: 'ONLY users with e-mail addresses that match these domain(s) will be able to sign-up. Wildcards allowed. Enter multiple entries on separate lines. Ex: domain.com, *.domain.com'
      optional :outbound_local_requests_whitelist, type: Array[String], coerce_with: Validations::Types::CommaSeparatedToArray.coerce, desc: 'List of trusted domains or IP addresses to which local requests are allowed when local requests for webhooks and integrations are disabled.'
      optional :email_otp_enabled, type: Boolean, desc: 'Enable Email-based one-time passwords (OTP) as a multi-factor authentication method.'
      optional :iframe_rendering_enabled, type: Boolean, desc: 'Allow rendering of iframes in Markdown.'
      optional :iframe_rendering_allowlist, type: Array[String], coerce_with: Validations::Types::CommaSeparatedToArray.coerce, desc: 'Allowed iframe src host[:port] entries. Enter multiple entries separated by commas or on separate lines.'
      optional :iframe_rendering_allowlist_raw, type: String, desc: 'Raw newline- or comma-separated list of allowed iframe src host[:port] entries.'
      optional :eks_integration_enabled, type: Boolean, desc: 'Enable integration with Amazon EKS'
      given eks_integration_enabled: ->(val) { val } do
        requires :eks_account_id, type: String, desc: 'Amazon account ID for EKS integration'
        requires :eks_access_key_id, type: String, desc: 'Access key ID for the EKS integration IAM user'
        requires :eks_secret_access_key, type: String, desc: 'Secret access key for the EKS integration IAM user'
      end
      optional :email_author_in_body, type: Boolean, desc: 'Some email servers do not support overriding the email sender name. Enable this option to include the name of the author of the issue, merge request or comment in the email body instead.'
      optional :email_confirmation_setting, type: String, values: ApplicationSetting.email_confirmation_settings.keys, desc: "Email confirmation setting, possible values: `off`, `soft`, and `hard`"
      optional :enabled_git_access_protocol, type: String, values: %w[ssh http all], desc: 'Allow only the selected protocols to be used for Git access.'
      optional :gitpod_enabled, type: Boolean, desc: 'Enable Gitpod'
      given gitpod_enabled: ->(val) { val } do
        requires :gitpod_url, type: String, desc: 'The configured Gitpod instance URL'
      end
      optional :gitaly_timeout_default, type: Integer, desc: 'Default Gitaly timeout, in seconds. Set to 0 to disable timeouts.'
      optional :gitaly_timeout_fast, type: Integer, desc: 'Gitaly fast operation timeout, in seconds. Set to 0 to disable timeouts.'
      optional :gitaly_timeout_medium, type: Integer, desc: 'Medium Gitaly timeout, in seconds. Set to 0 to disable timeouts.'
      optional :grafana_enabled, type: Boolean, desc: 'Enable Grafana'
      optional :grafana_url, type: String, desc: 'Grafana URL'
      optional :gravatar_enabled, type: Boolean, desc: 'Flag indicating if the Gravatar service is enabled'
      optional :help_page_hide_commercial_content, type: Boolean, desc: 'Hide marketing-related entries from help'
      optional :help_page_support_url, type: String, desc: 'Alternate support URL for help page and help dropdown'
      optional :help_page_documentation_base_url, type: String, desc: 'Alternate documentation pages URL'
      optional :help_page_text, type: String, desc: 'Custom text displayed on the help page'
      optional :home_page_url, type: String, desc: 'We will redirect non-logged in users to this page'
      optional :housekeeping_enabled, type: Boolean, desc: 'Enable automatic repository housekeeping (git repack, git gc)'
      given housekeeping_enabled: ->(val) { val } do
        optional :housekeeping_full_repack_period, type: Integer, desc: "Number of Git pushes after which a full 'git repack' is run."
        optional :housekeeping_gc_period, type: Integer, desc: "Number of Git pushes after which 'git gc' is run."
        optional :housekeeping_incremental_repack_period, type: Integer, desc: "Number of Git pushes after which an incremental 'git repack' is run."

        optional :housekeeping_optimize_repository_period, type: Integer, desc: "Number of Git pushes after which Gitaly is asked to optimize a repository."

        # Requires either all three deprecated attributes (housekeeping_full_repack_period, housekeeping_gc_period, housekeeping_incremental_repack_period) or housekeeping_optimize_repository_period
        all_or_none_of :housekeeping_full_repack_period, :housekeeping_gc_period, :housekeeping_incremental_repack_period
        exactly_one_of :housekeeping_incremental_repack_period, :housekeeping_optimize_repository_period
      end
      optional :html_emails_enabled, type: Boolean, desc: 'By default GitLab sends emails in HTML and plain text formats so mail clients can choose what format to use. Disable this option if you only want to send emails in plain text format.'
      optional :import_sources, type: Array[String], coerce_with: Validations::Types::CommaSeparatedToArray.coerce,
        values: %w[github bitbucket bitbucket_server fogbugz git gitlab_project gitea manifest],
        desc: 'Enabled sources for code import during project creation. OmniAuth must be configured for GitHub, Bitbucket, and GitLab.com'
      optional :invisible_captcha_enabled, type: Boolean, desc: 'Enable Invisible Captcha spam detection during signup.'
      optional :max_artifacts_size, type: Integer, desc: "Set the maximum file size for each job's artifacts"
      optional :max_attachment_size, type: Integer, desc: 'Maximum attachment size in MB'
      optional :max_export_size, type: Integer, desc: 'Maximum export size in MB'
      optional :max_github_response_size_limit, type: Integer, desc: "Maximum allowed size in MB for GitHub API responses. 0 for unlimited."
      optional :max_github_response_json_value_count, type: Integer, desc: "Maximum allowed object count for GitHub API responses. 0 for unlimited. Count is an estimate based on the number of : , { and [ occurrences in the response."
      optional :max_import_size, type: Integer, desc: 'Maximum import size in MB'
      optional :max_import_remote_file_size, type: Integer, desc: 'Maximum remote file size in MB for imports from external object storages'
      optional :max_decompressed_archive_size, type: Integer, desc: 'Maximum decompressed size in MB'
      optional :max_pages_size, type: Integer, desc: 'Maximum size of pages in MB'
      optional :max_pages_custom_domains_per_project, type: Integer, desc: 'Maximum number of GitLab Pages custom domains per project'
      optional :max_terraform_state_size_bytes, type: Integer, desc: "Maximum size in bytes of the Terraform state file. Set this to 0 for unlimited file size."
      optional :metrics_method_call_threshold, type: Integer, desc: 'A method call is only tracked when it takes longer to complete than the given amount of milliseconds.'
      optional :password_authentication_enabled, type: Boolean, desc: 'Flag indicating if password authentication is enabled for the web interface' # support legacy names, can be removed in v5
      optional :password_authentication_enabled_for_web, type: Boolean, desc: 'Flag indicating if password authentication is enabled for the web interface'
      mutually_exclusive :password_authentication_enabled_for_web, :password_authentication_enabled, :signin_enabled
      optional :password_authentication_enabled_for_git, type: Boolean, desc: 'Flag indicating if password authentication is enabled for Git over HTTP(S)'
      optional :performance_bar_allowed_group_id, type: String, desc: 'Deprecated: Use :performance_bar_allowed_group_path instead. Path of the group that is allowed to toggle the performance bar.' # support legacy names, can be removed in v6
      optional :performance_bar_allowed_group_path, type: String, desc: 'Path of the group that is allowed to toggle the performance bar.'
      optional :performance_bar_enabled, type: String, desc: 'Deprecated: Pass `performance_bar_allowed_group_path: nil` instead. Allow enabling the performance.' # support legacy names, can be removed in v6
      optional :personal_access_token_prefix, type: String, desc: 'Prefix to prepend to all personal access tokens'
      optional :require_personal_access_token_expiry, type: Boolean, desc: 'Flag indicating if Personal / Group / Project access token expiry is required'
      optional :kroki_enabled, type: Boolean, desc: 'Enable Kroki'
      given kroki_enabled: ->(val) { val } do
        requires :kroki_url, type: String, desc: 'The Kroki server URL'
      end
      optional :plantuml_enabled, type: Boolean, desc: 'Enable PlantUML'
      given plantuml_enabled: ->(val) { val } do
        requires :plantuml_url, type: String, desc: 'The PlantUML server URL'
      end
      optional :diagramsnet_enabled, type: Boolean, desc: 'Enable Diagrams.net'
      given diagramsnet_enabled: ->(val) { val } do
        requires :diagramsnet_url, type: String, desc: 'The Diagrams.net server URL'
      end
      optional :polling_interval_multiplier, type: BigDecimal, desc: 'Interval multiplier used by endpoints that perform polling. Set to 0 to disable polling.'
      optional :project_export_enabled, type: Boolean, desc: 'Enable project export'
      optional :prometheus_metrics_enabled, type: Boolean, desc: 'Enable Prometheus metrics'
      optional :push_event_hooks_limit, type: Integer, desc: "Maximum number of changes (branches or tags) in a single push above which webhooks and integrations are not triggered. Setting to `0` does not disable throttling."
      optional :push_event_activities_limit, type: Integer, desc: 'Maximum number of changes (branches or tags) in a single push above which a bulk push event is created. Setting to `0` does not disable throttling.'
      optional :recaptcha_enabled, type: Boolean, desc: 'Helps prevent bots from creating accounts'
      given recaptcha_enabled: ->(val) { val } do
        requires :recaptcha_site_key, type: String, desc: 'Generate site key at http://www.google.com/recaptcha'
        requires :recaptcha_private_key, type: String, desc: 'Generate private key at http://www.google.com/recaptcha'
      end
      optional :login_recaptcha_protection_enabled, type: Boolean, desc: 'Helps prevent brute-force attacks'
      given login_recaptcha_protection_enabled: ->(val) { val } do
        requires :recaptcha_site_key, type: String, desc: 'Generate site key at http://www.google.com/recaptcha'
        requires :recaptcha_private_key, type: String, desc: 'Generate private key at http://www.google.com/recaptcha'
      end
      optional :repository_checks_enabled, type: Boolean, desc: "GitLab will periodically run 'git fsck' in all project and wiki repositories to look for silent disk corruption issues."
      optional :repository_storages_weighted, type: Hash, coerce_with: Validations::Types::HashOfIntegerValues.coerce, desc: 'Storage paths for new projects with a weighted value ranging from 0 to 100', documentation: { type: 'Object', additional_properties: Integer }
      optional :require_two_factor_authentication, type: Boolean, desc: 'Require all users to set up Two-factor authentication'
      given require_two_factor_authentication: ->(val) { val } do
        requires :two_factor_grace_period, type: Integer, desc: 'Amount of time (in hours) that users are allowed to skip forced configuration of two-factor authentication'
      end
      optional :restricted_visibility_levels, type: Array[String], coerce_with: Validations::Types::CommaSeparatedToArray.coerce, desc: 'Selected levels cannot be used by non-admin users for groups, projects or snippets. If the public level is restricted, user profiles are only visible to logged in users.'
      optional :session_expire_delay, type: Integer, desc: 'Session duration in minutes. GitLab restart is required to apply changes.'
      optional :session_expire_from_init, type: Boolean, desc: 'Expires sessions based off the creation date rather than last activity'
      optional :shared_runners_enabled, type: Boolean, desc: 'Enable shared runners for new projects'
      given shared_runners_enabled: ->(val) { val } do
        requires :shared_runners_text, type: String, desc: 'Shared runners text '
      end
      optional :valid_runner_registrars, type: Array[String], desc: 'List of types which are allowed to register a GitLab runner'
      optional :signin_enabled, type: Boolean, desc: 'Flag indicating if password authentication is enabled for the web interface' # support legacy names, can be removed in v5
      optional :signup_enabled, type: Boolean, desc: 'Flag indicating if sign up is enabled'
      optional :sourcegraph_enabled, type: Boolean, desc: 'Enable Sourcegraph'
      optional :sourcegraph_public_only, type: Boolean, desc: 'Only allow public projects to communicate with Sourcegraph'
      given sourcegraph_enabled: ->(val) { val } do
        requires :sourcegraph_url, type: String, desc: 'The configured Sourcegraph instance URL'
      end
      optional :spam_check_endpoint_enabled, type: Boolean, desc: 'Enable Spam Check via external API endpoint'
      given spam_check_endpoint_enabled: ->(val) { val } do
        requires :spam_check_endpoint_url, type: String, desc: 'The URL of the external Spam Check service endpoint'
      end
      optional :terminal_max_session_time, type: Integer, desc: 'Maximum time for web terminal websocket connection (in seconds). Set to 0 for unlimited time.'
      optional :usage_ping_enabled, type: Boolean, desc: 'Every week GitLab will report license usage back to GitLab, Inc.'
      optional :local_markdown_version, type: Integer, desc: 'Local markdown version, increase this value when any cached markdown should be invalidated'
      optional :allow_local_requests_from_hooks_and_services, type: Boolean, desc: 'Deprecated: Use :allow_local_requests_from_web_hooks_and_services instead. Allow requests to the local network from hooks and services.' # support legacy names, can be removed in v5
      optional :mailgun_events_enabled, type: Grape::API::Boolean, desc: 'Enable Mailgun event receiver'
      given mailgun_events_enabled: ->(val) { val } do
        requires :mailgun_signing_key, type: String, desc: 'The Mailgun HTTP webhook signing key for receiving events from webhook'
      end
      optional :snowplow_enabled, type: Grape::API::Boolean, desc: 'Enable Snowplow tracking'
      given snowplow_enabled: ->(val) { val } do
        requires :snowplow_collector_hostname, type: String, desc: 'The Snowplow collector hostname'
        optional :snowplow_cookie_domain, type: String, desc: 'The Snowplow cookie domain'
        optional :snowplow_app_id, type: String, desc: 'The Snowplow site name / application id'
      end
      optional :issues_create_limit, type: Integer, desc: "Maximum number of issue creation requests allowed per minute per user. Set to 0 for unlimited requests per minute."
      optional :raw_blob_request_limit, type: Integer, desc: "Maximum number of requests per minute for each raw path. Set to 0 for unlimited requests per minute."
      optional :raw_blob_request_limit_unauthenticated, type: Integer, desc: "Maximum number of requests per minute for a raw blob for unauthenticated requests. Set to 0 for unlimited requests per minute."
      optional :wiki_page_max_content_bytes, type: Integer, desc: "Maximum wiki page content size in bytes"
      optional :description_and_note_max_size, type: Integer, desc: 'Maximum work item, merge request, and vulnerability description and comment content size in bytes.'
      optional :wiki_asciidoc_allow_uri_includes, type: Boolean, desc: "Allow URI includes for AsciiDoc wiki pages"
      optional :require_admin_approval_after_user_signup, type: Boolean, desc: 'Require explicit admin approval for new signups'
      optional :whats_new_variant, type: String, values: ApplicationSetting.whats_new_variants.keys, desc: "What's new variant, possible values: `all_tiers`, `current_tier`, and `disabled`."
      optional :floc_enabled, type: Grape::API::Boolean, desc: 'Enable FloC (Federated Learning of Cohorts)'
      optional :user_deactivation_emails_enabled, type: Boolean, desc: 'Send emails to users upon account deactivation'
      optional :show_migrate_from_jenkins_banner, type: Boolean, desc: 'Enable Jenkins migration banner'
      optional :enable_artifact_external_redirect_warning_page, type: Boolean, desc: 'Show the external redirect page that warns you about user-generated content in GitLab Pages'
      optional :users_get_by_id_limit, type: Integer, desc: "Maximum number of calls to the /users/:id API per 10 minutes per user. Set to 0 for unlimited requests."
      optional :runner_token_expiration_interval, type: Integer, desc: 'Token expiration interval for shared runners, in seconds'
      optional :group_runner_token_expiration_interval, type: Integer, desc: 'Token expiration interval for group runners, in seconds'
      optional :project_runner_token_expiration_interval, type: Integer, desc: 'Token expiration interval for project runners, in seconds'
      optional :pipeline_limit_per_project_user_sha, type: Integer, desc: "Maximum number of pipeline creation requests allowed per minute per user and commit. Set to 0 for unlimited requests per minute."
      optional :pipeline_limit_per_user, type: Integer, desc: "Maximum number of pipeline creation requests allowed per minute per user. Set to 0 for unlimited requests per minute."
      optional :ci_lint_limit_per_user, type: Integer, desc: "Maximum number of CI Lint requests allowed per minute per user. Set to 0 for unlimited requests per minute."
      optional :jira_connect_application_key, type: String, desc: "ID of the OAuth application used to authenticate with the GitLab for Jira Cloud app."
      optional :jira_connect_public_key_storage_enabled, type: Boolean, desc: 'Enable public key storage for the GitLab for Jira Cloud app.'
      optional :jira_connect_proxy_url, type: String, desc: "URL of the GitLab instance used as a proxy for the GitLab for Jira Cloud app."
      optional :jira_forge_app_id, type: String, desc: "Atlassian Forge app ID (ARI) of the GitLab for Jira Cloud app, used to verify inbound Forge Invocation Tokens."
      optional :bulk_import_concurrent_pipeline_batch_limit, type: Integer, desc: 'Maximum simultaneous direct transfer batch exports to process.'
      optional :concurrent_relation_batch_export_limit, type: Integer, desc: 'Maximum number of simultaneous batch export jobs to process.'
      optional :bulk_import_enabled, type: Boolean, desc: 'Enable migrating GitLab groups and projects by direct transfer'
      optional :bulk_import_max_download_file, type: Integer, desc: 'Maximum download file size in MB when importing from source GitLab instances by direct transfer'
      optional :autocomplete_users_limit, type: Integer, desc: 'Rate limit for authenticated requests to users autocomplete endpoint'
      optional :autocomplete_users_unauthenticated_limit, type: Integer, desc: 'Rate limit for authenticated requests to users autocomplete endpoint'
      optional :concurrent_github_import_jobs_limit, type: Integer, desc: 'Github Importer maximum number of simultaneous import jobs'
      optional :concurrent_bitbucket_import_jobs_limit, type: Integer, desc: 'Bitbucket Cloud Importer maximum number of simultaneous import jobs'
      optional :concurrent_bitbucket_server_import_jobs_limit, type: Integer, desc: 'Bitbucket Server Importer maximum number of simultaneous import jobs'
      optional :allow_runner_registration_token, type: Boolean, desc: 'Allow registering runners using a registration token'
      optional :ci_max_includes, type: Integer, desc: 'Maximum number of includes per pipeline'
      optional :ci_max_caches_per_job, type: Integer, desc: 'Maximum number of caches that can be defined in a single CI/CD job'
      optional :ci_job_live_trace_enabled, type: Boolean, desc: 'Turn on incremental logging for job logs.'
      optional :git_push_pipeline_limit, type: Integer, desc: 'Set the limit for pipelines and branches that can be triggered when creating a Git push. Set to 0 to disable the limit'
      optional :security_policy_global_group_approvers_enabled, type: Boolean, desc: 'Query scan result policy approval groups globally'
      optional :slack_app_enabled, type: Grape::API::Boolean, desc: 'Enable the GitLab for Slack app'
      given slack_app_enabled: ->(val) { val } do
        requires :slack_app_id, type: String, desc: 'The client ID of the GitLab for Slack app'
        requires :slack_app_secret, type: String, desc: 'The client secret of the GitLab for Slack app. Used for authenticating OAuth requests from the app'
        requires :slack_app_signing_secret, type: String, desc: 'The signing secret of the GitLab for Slack app. Used for authenticating API requests from the app'
        requires :slack_app_verification_token, type: String, desc: 'The verification token of the GitLab for Slack app. This method of authentication is deprecated by Slack and used only for authenticating slash commands from the app'
      end
      optional :namespace_aggregation_schedule_lease_duration_in_seconds, type: Integer, desc: 'Maximum duration (in seconds) between refreshes of namespace statistics (Default: 300)'
      optional :project_jobs_api_rate_limit, type: Integer, desc: 'Maximum authenticated requests to /project/:id/jobs per minute'
      optional :security_txt_content, type: String, desc: 'Public security contact information made available at https://gitlab.example.com/.well-known/security.txt'
      optional :downstream_pipeline_trigger_limit_per_project_user_sha, type: Integer, desc: 'Maximum number of downstream pipelines that can be triggered per minute (for a given project, user, and commit).'
      optional :ai_action_api_rate_limit, type: Integer, desc: 'Maximum requests a user can make per 8 hours to aiAction endpoint'
      optional :code_suggestions_api_rate_limit, type: Integer, desc: 'Maximum requests a user can make per minute to code suggestions endpoint'
      optional :resource_usage_limits, type: JSON, desc: 'Definition for resource usage limits enforced in Sidekiq workers'
      optional :vscode_extension_marketplace, type: Hash, desc: 'Settings for VS Code Extension Marketplace' do
        optional :enabled, type: Boolean, desc: 'Enables VS Code Extension Marketplace for Web IDE and Workspaces'
        optional :preset, type: String, desc: "The preset configuration of URL's for the VS Code Extension Marketplace"
        optional :custom_values, type: Hash, desc: "VS Code Extension Marketplace URL's when preset is 'custom'"
      end
      optional :enable_language_server_restrictions, type: Boolean, desc: 'Enables enforcing language server restrictions'
      optional :minimum_language_server_version, type: String, desc: 'The minimum language server version to accept requests from'
      optional :terraform_state_encryption_enabled, type: Boolean, desc: 'Enable encryption for Terraform state files'
      optional :logging_field_schema_version, type: Integer,
        values: ApplicationSetting::LOGGING_FIELD_SCHEMA_VERSIONS,
        desc: 'Logging field schema version (v0, v1, …). Cannot be downgraded.'
      optional :logging_field_dual_emit_target, type: Integer,
        values: ApplicationSetting::LOGGING_FIELD_SCHEMA_VERSIONS.reject(&:zero?),
        allow_blank: true,
        desc: 'Version to dual-emit alongside schema_version. Must be strictly greater than schema_version, or omit/null to disable.'

      Gitlab::SSHPublicKey.supported_types.each do |type|
        optional :"#{type}_key_restriction",
          type: Integer,
          values: KeyRestrictionValidator.supported_key_restrictions(type),
          desc: "Restrictions on the complexity of uploaded #{type.upcase} keys. A value of #{ApplicationSetting::FORBIDDEN_KEY_VALUE} disables all #{type.upcase} keys."
      end

      # The parameters below are also declared by the `optional_attributes` splat further
      # down, which cannot carry per-parameter metadata. Descriptions are copied verbatim
      # from doc/api/settings.md. Only `desc` is set: adding `type` here would make Grape
      # reject values that ActiveRecord currently coerces, which is a breaking change.
      # See https://gitlab.com/gitlab-org/gitlab/-/work_items/612735
      # rubocop:disable API/ParameterType -- types are added in https://gitlab.com/gitlab-org/gitlab/-/work_items/618695
      optional :allow_account_deletion,
        desc: 'Set to `true` to allow users to delete their accounts. Premium and Ultimate only.'
      optional :allow_application_default_credentials_for_offline_transfer,
        desc: 'Allow Google Cloud Application Default Credentials for offline transfer. Even when enabled, only ' \
          'administrators can use these credentials, and the bucket name must start with `gitlab-offline-transfer-`. ' \
          'Has no effect on GitLab.com. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/602489) in ' \
          'GitLab 19.3.'
      optional :allow_bypass_placeholder_confirmation,
        desc: 'Skip confirmation when administrators reassign placeholder users. ' \
          '[Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/534330) in GitLab 18.0.'
      optional :allow_local_requests_from_system_hooks, desc: 'Allow requests to the local network from system hooks.'
      optional :allow_local_requests_from_web_hooks_and_services,
        desc: 'Allow requests to the local network from webhooks and integrations.'
      optional :allow_project_creation_for_guest_and_below,
        desc: 'Indicates whether users assigned up to the Guest role can create groups and personal projects. ' \
          'Defaults to `true`.'
      optional :allow_s3_compatible_storage_for_offline_transfer,
        desc: 'Allow S3-compatible object storage for offline transfer. ' \
          '[Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/579705) in GitLab 18.9.'
      optional :archive_builds_in_human_readable,
        desc: 'Set the duration for which the jobs are considered as old and expired. After that time passes, the ' \
          'jobs are archived and no longer able to be retried. Make it empty to never expire jobs. It has to be no ' \
          'less than 1 day, for example: `15 days`, `1 month`, `2 years`.'
      optional :asciidoc_max_includes,
        desc: 'Maximum limit of AsciiDoc include directives being processed in any one document. Default: 32. ' \
          'Maximum: 64.'
      optional :authorized_keys_enabled,
        desc: 'By default, the `authorized_keys` file supports Git over SSH without additional configuration. GitLab ' \
          'can be optimized to authenticate SSH keys via the database file. Only disable this if you have configured ' \
          'your OpenSSH server to use the AuthorizedKeysCommand.'
      optional :auto_accept_awarded_achievements,
        desc: 'If `true`, newly awarded achievements are accepted automatically and appear on user profiles ' \
          'immediately. Does not affect achievements awarded before this setting is enabled. Recipients can still ' \
          'hide any achievement. Default value: `false`. ' \
          '[Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/607750) in GitLab 19.4.'
      optional :auto_devops_domain,
        desc: "Specify a domain to use by default for every project's Auto Review Apps and Auto Deploy stages."
      optional :auto_devops_enabled,
        desc: 'Enable Auto DevOps for projects by default. It automatically builds, tests, and deploys applications ' \
          'based on a predefined CI/CD configuration.'
      optional :bulk_import_max_download_file_size,
        desc: 'Maximum download file size when importing from source GitLab instances by direct transfer.'
      optional :can_create_group, desc: 'Indicates whether users can create top-level groups. Defaults to `true`.'
      optional :ci_delete_pipelines_in_seconds_limit_human_readable,
        desc: 'Maximum value that is allowed for configuring pipeline retention. Defaults to `1 year`.'
      optional :ci_max_total_yaml_size_bytes,
        desc: 'The maximum amount of memory, in bytes, that can be allocated for the pipeline configuration, with ' \
          'all included YAML configuration files.'
      optional :ci_partitions_in_seconds_limit,
        desc: 'The time window, in seconds, before new CI partitions are created and the system switches to the next ' \
          'set of partitions. Must be between 1 month and 6 months. Default is 1 month (`2592000`). Write-only. Not ' \
          'returned in GET responses. Deprecated in favor of `ci_partitions_in_seconds_limit_human_readable` and is ' \
          'scheduled for removal in API v5.'
      optional :ci_partitions_in_seconds_limit_human_readable,
        desc: 'The time window before new CI partitions are created and the system switches to the next set of ' \
          'partitions. Must be between `1 month` and `6 months`. Defaults to `1 month`.'
      optional :commit_email_hostname, desc: 'Custom hostname (for private commit emails).'
      optional :container_expiration_policies_enable_historic_entries, desc: 'Enable cleanup policies for all projects.'
      optional :container_registry_cleanup_tags_service_max_list_size,
        desc: 'The maximum number of tags that can be deleted in a single execution of cleanup policies.'
      optional :container_registry_delete_tags_service_timeout,
        desc: 'The maximum time, in seconds, that the cleanup process can take to delete a batch of tags for cleanup ' \
          'policies.'
      optional :container_registry_expiration_policies_caching,
        desc: 'Caching during the execution of cleanup policies.'
      optional :container_registry_expiration_policies_worker_capacity, desc: 'Number of workers for cleanup policies.'
      optional :custom_http_clone_url_root, desc: 'Set a custom Git clone URL for HTTP(S).'
      optional :default_branch_name, desc: 'Set the initial branch name for all projects in an instance.'
      optional :default_dark_syntax_highlighting_theme,
        desc: 'Default dark mode syntax highlighting theme for users who are new or not signed in. See [IDs of ' \
          'available themes](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/themes.rb#L16).'
      optional :default_preferred_language, desc: 'Default preferred language for users who are not logged in.'
      optional :default_syntax_highlighting_theme,
        desc: 'Default syntax highlighting theme for users who are new or not signed in. See [IDs of available ' \
          'themes](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/themes.rb#L16).'
      optional :delete_inactive_projects, desc: 'Enable dormant project deletion. Default is `false`.'
      optional :deletion_adjourned_period,
        desc: 'Number of days to wait before deleting a project or group that is marked for deletion. Value must be ' \
          'between `1` and `90`. Defaults to `30`.'
      optional :diff_max_commits, desc: 'Maximum number of diff commits per merge request.'
      optional :diff_max_files, desc: 'Maximum files in a diff.'
      optional :diff_max_lines, desc: 'Maximum lines in a diff.'
      optional :diff_max_patch_bytes, desc: 'Maximum diff patch size, in bytes.'
      optional :diff_max_versions, desc: 'Maximum number of diff versions per merge request.'
      optional :disable_password_authentication_for_users_with_sso_identities,
        desc: 'Disable password authentication in the web interface for users with an SSO identity. This does not ' \
          'affect Git operations over HTTP(S). Default is `false`.'
      optional :dns_rebinding_protection_enabled, desc: 'Enforce DNS-rebinding attack protection.'
      optional :email_restrictions,
        desc: 'Regular expression that is checked against the email used during registration.'
      optional :email_restrictions_enabled, desc: 'Prevent new users from creating an account by email.'
      optional :enforce_terms, desc: '(**If enabled, requires**: `terms`) Enforce application ToS to all users.'
      optional :external_auth_client_cert,
        desc: '(**If enabled, requires**: `external_auth_client_key`) The certificate to use to authenticate with ' \
          'the external authorization service.'
      optional :external_auth_client_key,
        desc: 'Private key for the certificate when authentication is required for the external authorization ' \
          'service, this is encrypted when stored.'
      optional :external_auth_client_key_pass,
        desc: 'Passphrase to use for the private key when authenticating with the external service this is encrypted ' \
          'when stored.'
      optional :external_authorization_service_default_label,
        desc: 'The default classification label to use when requesting authorization and no classification label has ' \
          'been specified on the project.'
      optional :external_authorization_service_enabled,
        desc: '(**If enabled, requires**: `external_authorization_service_default_label`, ' \
          '`external_authorization_service_timeout`, and `external_authorization_service_url`) Enable using an ' \
          'external authorization service for accessing projects.'
      optional :external_authorization_service_timeout,
        desc: 'The timeout after which an authorization request is aborted, in seconds. When a request times out, ' \
          'access is denied to the user. (min: 0.001, max: 10, step: 0.001).'
      optional :external_authorization_service_url, desc: 'URL to which authorization requests are directed.'
      optional :external_pipeline_validation_service_timeout,
        desc: 'How long to wait for a response from the pipeline validation service. Assumes `OK` if it times out.'
      optional :external_pipeline_validation_service_token,
        desc: 'Optional. Token to include as the `X-Gitlab-Token` header in requests to the URL in ' \
          '`external_pipeline_validation_service_url`.'
      optional :external_pipeline_validation_service_url, desc: 'URL to use for pipeline validation requests.'
      optional :failed_login_attempts_unlock_period_in_minutes,
        desc: 'Time period in minutes after which the user is unlocked when maximum number of failed sign-in ' \
          'attempts reached.'
      optional :first_day_of_week,
        desc: 'Start day of the week for calendar views and date pickers. Valid values are `0` (default) for Sunday, ' \
          '`1` for Monday, and `6` for Saturday.'
      optional :gitlab_dedicated_instance, desc: 'Indicates whether the instance was provisioned for GitLab Dedicated.'
      optional :gitlab_environment_toolkit_instance,
        desc: 'Indicates whether the instance was provisioned with the GitLab Environment Toolkit for Service Ping ' \
          'reporting.'
      optional :gitlab_product_usage_data_enabled,
        desc: 'Indicates if product usage data collection is enabled. When the `GITLAB_PRODUCT_USAGE_DATA_ENABLED` ' \
          'environment variable is set, the API returns the effective value from the environment variable.'
      optional :gitlab_shell_operation_limit,
        desc: 'Maximum number of Git operations per minute a user can perform. Default: `600`.'
      optional :hashed_storage_enabled,
        desc: 'Create new projects using hashed storage paths: Enable immutable, hash-based paths and repository ' \
          'names to store repositories on disk. This prevents repositories from having to be moved or renamed when ' \
          'the Project URL changes and may improve disk I/O performance. (Always enabled in GitLab versions 13.0 and ' \
          'later, configuration is scheduled for removal in 14.0)'
      optional :hide_third_party_offers, desc: 'Do not display offers from third parties in GitLab.'
      optional :inactive_projects_delete_after_months,
        desc: 'If `delete_inactive_projects` is `true`, the time (in months) to wait before deleting dormant ' \
          'projects. Default is `2`.'
      optional :inactive_projects_min_size_mb,
        desc: 'If `delete_inactive_projects` is `true`, the minimum repository size for projects to be checked for ' \
          'inactivity. Default is `0`.'
      optional :inactive_projects_send_warning_email_after_months,
        desc: 'If `delete_inactive_projects` is `true`, sets the time (in months) to wait before emailing ' \
          'Maintainers that the project is scheduled to be deleted because it is dormant. Default is `1`.'
      optional :inactive_resource_access_tokens_delete_after_days,
        desc: 'Specifies retention period for inactive project and group access tokens. Default is `30`.'
      optional :include_optional_metrics_in_service_ping,
        desc: 'Whether or not optional metrics are enabled in Service Ping.'
      optional :keep_latest_artifact,
        desc: 'Prevent the deletion of the artifacts from the most recent successful jobs, regardless of the expiry ' \
          'time. Enabled by default.'
      optional :kroki_diagram_proxy_enabled, desc: 'Enable Kroki diagram proxy. Default is `false`.'
      optional :kroki_formats,
        desc: 'Additional formats supported by the Kroki instance. Possible values are `true` or `false` for formats ' \
          '`bpmn`, `blockdiag`, `excalidraw`, and `mermaid` in the format `<format>: true` or `<format>: false`.'
      optional :lock_require_sha_for_merge,
        desc: 'Enforce the `require_sha_for_merge` setting for all groups on the instance. ' \
          '[Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/236732) in GitLab 19.2.'
      optional :max_http_decompressed_size,
        desc: 'Maximum allowed size in MiB for Gzip-compressed HTTP responses from outbound requests after ' \
          'decompression. 0 for unlimited.'
      optional :max_http_response_csv_structural_chars,
        desc: 'Maximum allowed object count in CSV HTTP responses from outbound requests. Count is an estimate based ' \
          'on the number of `,`, `;`, `\t`, and `\n` occurrences in the response. Introduced in GitLab 18.4.'
      optional :max_http_response_json_depth,
        desc: 'Maximum allowed nesting depth in JSON HTTP responses from outbound requests.'
      optional :max_http_response_json_structural_chars,
        desc: 'Maximum allowed object count in JSON HTTP responses from outbound requests. Count is an estimate ' \
          'based on the number of `:`, `,`, `{`, and `[` occurrences in the response. Introduced in GitLab 18.4.'
      optional :max_http_response_size_limit,
        desc: 'Maximum allowed size in MiB for HTTP responses from outbound requests. 0 for unlimited. Applicable ' \
          'for integrations, importers, and webhooks. Introduced in GitLab 18.4.'
      optional :max_http_response_xml_structural_chars,
        desc: 'Maximum allowed object count in XML HTTP responses from outbound requests. Count is an estimate based ' \
          'on the number of `<`, and `=` occurrences in the response. Introduced in GitLab 18.4.'
      optional :max_login_attempts, desc: 'Maximum number of sign-in attempts before locking out the user.'
      optional :max_yaml_depth,
        desc: 'The maximum depth of nested CI/CD configuration added with the `include` keyword. Default: `100`.'
      optional :max_yaml_size_bytes,
        desc: 'The maximum size in bytes of a single CI/CD configuration file. Default: `2097152`.'
      optional :minimum_password_length,
        desc: 'Indicates whether passwords require a minimum length. Premium and Ultimate only.'
      optional :mirror_available,
        desc: 'Allow repository mirroring to configured by project Maintainers. If disabled, only Administrators can ' \
          'configure repository mirroring.'
      optional :notify_on_unknown_sign_in,
        desc: 'Enable sending notification if sign in from unknown IP address happens.'
      optional :offline_transfer_exports_enabled,
        desc: 'Enable exporting GitLab groups and projects by offline transfer. ' \
          '[Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/588971) in GitLab 19.3.'
      optional :offline_transfer_imports_enabled,
        desc: 'Enable importing GitLab groups and projects by offline transfer. ' \
          '[Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/588971) in GitLab 19.3.'
      optional :package_registry_allow_anyone_to_pull_option,
        desc: 'Enable to allow anyone to pull from package registry visible and changeable.'
      optional :package_registry_cleanup_policies_worker_capacity,
        desc: 'Number of workers assigned to the packages cleanup policies.'
      optional :pages_domain_verification_enabled,
        desc: 'Require users to prove ownership of custom domains. Domain verification is an essential security ' \
          'measure for public GitLab sites. Users are required to demonstrate they control a domain before it is ' \
          'enabled.'
      optional :pages_unique_domain_default_enabled,
        desc: 'Enable unique domains by default for Pages sites to avoid cookie sharing between sites under a given ' \
          'namespace. Default is `true`.'
      optional :plantuml_diagram_proxy_enabled, desc: 'Enable PlantUML diagram proxy. Default is `false`.'
      optional :projects_api_rate_limit_unauthenticated,
        desc: 'Maximum number of requests per 10 minutes per IP address for unauthenticated requests to the list ' \
          'all projects API. Default: 400. To disable throttling, set to 0.'
      optional :protected_ci_variables, desc: 'CI/CD variables are protected by default.'
      optional :rate_limiting_response_text,
        desc: "When rate limiting is enabled via the `throttle_*` settings, send this plain text response when a " \
          "rate limit is exceeded. 'Retry later' is sent if this is blank."
      optional :receive_max_input_size, desc: 'Maximum push size (MB).'
      optional :relation_export_batch_size,
        desc: 'The size of each batch when exporting batched relations. ' \
          '[Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/194607) in GitLab 18.2.'
      optional :remember_me_enabled, desc: 'Enable **Remember me** setting.'
      optional :require_admin_two_factor_authentication,
        desc: 'Allow administrators to require 2FA for all administrators on the instance.'
      optional :require_email_verification_on_account_locked,
        desc: 'If `true`, all users on the instance must verify their identity after suspicious sign-in activity is ' \
          'detected.'
      optional :require_sha_for_merge,
        desc: 'Instance default that requires a valid commit `sha` for calls to the merge a merge ' \
          'request endpoint. ' \
          '[Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/236732) in GitLab 19.2.'
      optional :runner_jobs_endpoints_api_limit,
        desc: 'Maximum number of requests per minute per job token for requests to `/jobs/*` requests to the runner ' \
          'jobs API endpoints. Default: 200. To disable throttling, set to 0. ' \
          '[Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/462537) in GitLab 18.5.'
      optional :runner_jobs_patch_trace_api_limit,
        desc: 'Maximum number of requests per minute per runner token for requests to the `PATCH /jobs/:id/trace` ' \
          'runner jobs API endpoint. Default: 2000. To disable throttling, set to 0. ' \
          '[Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/462537) in GitLab 18.5.'
      optional :runner_jobs_request_api_limit,
        desc: 'Maximum number of requests per minute per runner token for requests to the `/jobs/request` runner ' \
          'jobs API endpoint. Default: 2000. To disable throttling, set to 0. ' \
          '[Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/462537) in GitLab 18.5.'
      optional :search_rate_limit,
        desc: 'Maximum number of requests per minute for performing a search while authenticated. Default: 30. To ' \
          'disable throttling, set to 0.'
      optional :search_rate_limit_unauthenticated,
        desc: 'Maximum number of requests per minute for performing a search while unauthenticated. Default: 10. To ' \
          'disable throttling, set to 0.'
      optional :sidekiq_job_limiter_compression_threshold_bytes,
        desc: 'The threshold in bytes at which Sidekiq jobs are compressed before being stored in Redis. Default: ' \
          '100,000 bytes (100 KB).'
      optional :sidekiq_job_limiter_limit_bytes,
        desc: "The threshold in bytes at which Sidekiq jobs are rejected. Default: 0 bytes (doesn't reject any job)."
      optional :sidekiq_job_limiter_mode,
        desc: "`track` or `compress`. Sets the behavior for Sidekiq job size limits. Default: 'compress'."
      optional :sidekiq_timezone_override,
        desc: 'IANA timezone identifier (for example, `America/Chicago`) applied to all Sidekiq cron jobs. When ' \
          'blank, no override is applied and cron jobs use the Rails application timezone.'
      optional :sign_in_restrictions, desc: 'Application sign in restrictions.'
      optional :silent_admin_exports_enabled, desc: 'Enable Silent admin exports. Default is `false`.'
      optional :silent_mode_enabled, desc: 'Enable Silent mode. Default is `false`.'
      optional :snippet_size_limit, desc: 'Maximum snippet content size in **bytes**. Default: 52428800 Bytes (50 MB).'
      optional :snowplow_database_collector_hostname,
        desc: 'The Snowplow collector for database events hostname. (for example, `db-snowplow.trx.gitlab.net`)'
      optional :spam_check_api_key, desc: 'API key used by GitLab for accessing the Spam Check service endpoint.'
      optional :static_objects_external_storage_auth_token,
        desc: 'Authentication token for the external storage linked in `static_objects_external_storage_url`.'
      optional :static_objects_external_storage_url, desc: 'URL to an external storage for repository static objects.'
      optional :terms, desc: '(**Required by**: `enforce_terms`) Markdown content for the ToS.'
      optional :throttle_authenticated_api_enabled,
        desc: '(**If enabled, requires**: `throttle_authenticated_api_period_in_seconds` and ' \
          '`throttle_authenticated_api_requests_per_period`) Enable authenticated API request rate limit. Helps ' \
          'reduce request volume (for example, from crawlers or abusive bots).'
      optional :throttle_authenticated_api_period_in_seconds, desc: 'Rate limit period (in seconds).'
      optional :throttle_authenticated_api_requests_per_period, desc: 'Maximum requests per period per user.'
      optional :throttle_authenticated_git_http_enabled,
        desc: 'If `true`, enforces the authenticated Git HTTP request rate limit. Default value: `false`.'
      optional :throttle_authenticated_git_http_period_in_seconds,
        desc: 'Rate limit period in seconds. `throttle_authenticated_git_http_enabled` must be `true`. Default ' \
          'value: `3600`.'
      optional :throttle_authenticated_git_http_requests_per_period,
        desc: 'Maximum requests per period per user. `throttle_authenticated_git_http_enabled` must be `true`. ' \
          'Default value: `3600`.'
      optional :throttle_authenticated_packages_api_enabled,
        desc: '(**If enabled, requires**: `throttle_authenticated_packages_api_period_in_seconds` and ' \
          '`throttle_authenticated_packages_api_requests_per_period`) Enable authenticated API request rate limit. ' \
          'Helps reduce request volume (for example, from crawlers or abusive bots).'
      optional :throttle_authenticated_packages_api_period_in_seconds, desc: 'Rate limit period (in seconds).'
      optional :throttle_authenticated_packages_api_requests_per_period, desc: 'Maximum requests per period per user.'
      optional :throttle_authenticated_web_enabled,
        desc: '(**If enabled, requires**: `throttle_authenticated_web_period_in_seconds` and ' \
          '`throttle_authenticated_web_requests_per_period`) Enable authenticated web request rate limit. Helps ' \
          'reduce request volume (for example, from crawlers or abusive bots).'
      optional :throttle_authenticated_web_period_in_seconds, desc: 'Rate limit period (in seconds).'
      optional :throttle_authenticated_web_requests_per_period, desc: 'Maximum requests per period per user.'
      optional :throttle_unauthenticated_api_enabled,
        desc: '(**If enabled, requires**: `throttle_unauthenticated_api_period_in_seconds` and ' \
          '`throttle_unauthenticated_api_requests_per_period`) Enable unauthenticated API request rate limit. Helps ' \
          'reduce request volume (for example, from crawlers or abusive bots).'
      optional :throttle_unauthenticated_api_period_in_seconds, desc: 'Rate limit period in seconds.'
      optional :throttle_unauthenticated_api_requests_per_period, desc: 'Maximum requests per period per IP.'
      optional :throttle_unauthenticated_enabled,
        desc: '([Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/335300) in GitLab 14.3. Use ' \
          '`throttle_unauthenticated_web_enabled` or `throttle_unauthenticated_api_enabled` instead.) (**If enabled, ' \
          'requires**: `throttle_unauthenticated_period_in_seconds` and ' \
          '`throttle_unauthenticated_requests_per_period`) Enable unauthenticated web request rate limit. Helps ' \
          'reduce request volume (for example, from crawlers or abusive bots).'
      optional :throttle_unauthenticated_git_http_enabled,
        desc: 'If `true`, enforces the unauthenticated Git HTTP request rate limit. Default value: `false`.'
      optional :throttle_unauthenticated_git_http_period_in_seconds,
        desc: 'Rate limit period in seconds. `throttle_unauthenticated_git_http_enabled` must be `true`. Default ' \
          'value: `3600`.'
      optional :throttle_unauthenticated_git_http_requests_per_period,
        desc: 'Maximum requests per period per IP. `throttle_unauthenticated_git_http_enabled` must be `true`. ' \
          'Default value: `3600`.'
      optional :throttle_unauthenticated_packages_api_enabled,
        desc: '(**If enabled, requires**: `throttle_unauthenticated_packages_api_period_in_seconds` and ' \
          '`throttle_unauthenticated_packages_api_requests_per_period`) Enable unauthenticated API request rate ' \
          'limit. Helps reduce request volume (for example, from crawlers or abusive bots).'
      optional :throttle_unauthenticated_packages_api_period_in_seconds, desc: 'Rate limit period (in seconds).'
      optional :throttle_unauthenticated_packages_api_requests_per_period, desc: 'Maximum requests per period per user.'
      optional :throttle_unauthenticated_period_in_seconds,
        desc: '([Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/335300) in GitLab 14.3. Use ' \
          '`throttle_unauthenticated_web_period_in_seconds` or `throttle_unauthenticated_api_period_in_seconds` ' \
          'instead.) Rate limit period in seconds.'
      optional :throttle_unauthenticated_requests_per_period,
        desc: '([Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/335300) in GitLab 14.3. Use ' \
          '`throttle_unauthenticated_web_requests_per_period` or `throttle_unauthenticated_api_requests_per_period` ' \
          'instead.) Maximum requests per period per IP.'
      optional :throttle_unauthenticated_web_enabled,
        desc: '(**If enabled, requires**: `throttle_unauthenticated_web_period_in_seconds` and ' \
          '`throttle_unauthenticated_web_requests_per_period`) Enable unauthenticated web request rate limit. Helps ' \
          'reduce request volume (for example, from crawlers or abusive bots).'
      optional :throttle_unauthenticated_web_period_in_seconds, desc: 'Rate limit period in seconds.'
      optional :throttle_unauthenticated_web_requests_per_period, desc: 'Maximum requests per period per IP.'
      optional :time_tracking_limit_to_hours, desc: 'Limit display of time tracking units to hours. Default is `false`.'
      optional :top_level_group_creation_enabled, desc: 'Allows a user to create top-level-groups. Default is `true`.'
      optional :unique_ips_limit_enabled,
        desc: '(**If enabled, requires**: `unique_ips_limit_per_user` and `unique_ips_limit_time_window`) Limit sign ' \
          'in from multiple IPs.'
      optional :unique_ips_limit_per_user, desc: 'Maximum number of IPs per user.'
      optional :unique_ips_limit_time_window, desc: 'How many seconds an IP is counted towards the limit.'
      optional :update_runner_versions_enabled, desc: 'Fetch GitLab Runner release version data from GitLab.com.'
      optional :use_clickhouse_for_analytics,
        desc: 'Enables ClickHouse as a data source for analytics reports. ClickHouse must be configured for this ' \
          'setting to take effect. Available on Premium and Ultimate only.'
      optional :user_default_external, desc: 'Newly registered users are external by default.'
      optional :user_default_internal_regex,
        desc: 'Specify an email address regex pattern to identify default internal users.'
      optional :user_defaults_to_private_profile,
        desc: 'Newly created users have private profile by default. Defaults to `false`.'
      optional :user_oauth_applications,
        desc: 'Allow users to register any application to use GitLab as an OAuth provider. This setting does not ' \
          'affect group-level OAuth applications.'
      optional :user_show_add_ssh_key_message,
        desc: "When set to `false` disable the `You won't be able to pull or push repositories via SSH until you add " \
          "an SSH key to your profile` warning shown to users with no uploaded SSH key."
      optional :users_api_limit_followers,
        desc: 'Maximum number of requests per minute, per user or IP address. Default: 100. Set to `0` to disable ' \
          'limits. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181054) in GitLab 17.10.'
      optional :users_api_limit_following,
        desc: 'Maximum number of requests per minute, per user or IP address. Default: 100. Set to `0` to disable ' \
          'limits. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181054) in GitLab 17.10.'
      optional :users_api_limit_gpg_key,
        desc: 'Maximum number of requests per minute, per user or IP address. Default: 120. Set to `0` to disable ' \
          'limits. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181054) in GitLab 17.10.'
      optional :users_api_limit_gpg_keys,
        desc: 'Maximum number of requests per minute, per user or IP address. Default: 120. Set to `0` to disable ' \
          'limits. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181054) in GitLab 17.10.'
      optional :users_api_limit_status,
        desc: 'Maximum number of requests per minute, per user or IP address. Default: 240. Set to `0` to disable ' \
          'limits. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181054) in GitLab 17.10.'
      optional :version_check_enabled, desc: 'Let GitLab inform you when an update is available.'
      optional :web_hook_event_resend_limit,
        desc: 'Maximum number of webhook event resend requests per minute, per user, for a given project or group. ' \
          'Default: 5. Set to `0` to disable limits. ' \
          '[Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/587887) in GitLab 19.3.'
      optional :web_hook_test_limit,
        desc: 'Maximum number of webhook test requests per minute, per user, for a given project or group. Default: ' \
          '5. Set to `0` to disable limits. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/587887) in ' \
          'GitLab 19.3.'
      # rubocop:enable API/ParameterType

      use :optional_params_ee

      # rubocop:disable API/ParameterType, API/ParameterDescription -- `optional_attributes` is a dynamic value, cops do not recognise this pattern
      optional(*Helpers::SettingsHelpers.optional_attributes)
      # rubocop:enable API/ParameterType, API/ParameterDescription
      at_least_one_of(*Helpers::SettingsHelpers.optional_attributes)
    end
    route_setting :authorization, permissions: :update_application_setting, boundary_type: :instance
    put "application/settings" do
      attrs = declared_params(include_missing: false)

      # support legacy names, can be removed in v6
      if attrs.has_key?(:performance_bar_allowed_group_id)
        attrs[:performance_bar_allowed_group_path] = attrs.delete(:performance_bar_allowed_group_id)
      end

      # support legacy names, can be removed in v6
      if attrs.has_key?(:performance_bar_enabled)
        performance_bar_enabled = attrs.delete(:performance_bar_allowed_group_id)
        attrs[:performance_bar_allowed_group_path] = nil unless performance_bar_enabled
      end

      # support legacy names, can be removed in v5
      if attrs.has_key?(:signin_enabled)
        attrs[:password_authentication_enabled_for_web] = attrs.delete(:signin_enabled)
      elsif attrs.has_key?(:password_authentication_enabled)
        attrs[:password_authentication_enabled_for_web] = attrs.delete(:password_authentication_enabled)
      end

      # support legacy names, can be removed in v5
      if attrs.has_key?(:allow_local_requests_from_hooks_and_services)
        attrs[:allow_local_requests_from_web_hooks_and_services] = attrs.delete(:allow_local_requests_from_hooks_and_services)
      end

      # support legacy names, can be removed in v5
      if attrs.has_key?(:admin_notification_email)
        attrs[:abuse_notification_email] = attrs.delete(:admin_notification_email)
      end

      # support legacy names, can be removed in v5
      if attrs.has_key?(:asset_proxy_whitelist)
        attrs[:asset_proxy_allowlist] = attrs.delete(:asset_proxy_whitelist)
      end

      # Also accept these attributes under their new names.
      #
      # TODO: Once we rename the columns, we have to swap this around and keep supporting the old names until v5.
      # https://gitlab.com/gitlab-org/gitlab/-/issues/340031
      %w[enabled period_in_seconds requests_per_period].each do |suffix|
        old_name = :"throttle_unauthenticated_#{suffix}"
        new_name = :"throttle_unauthenticated_web_#{suffix}"
        attrs[old_name] = attrs.delete(new_name) if attrs.has_key?(new_name)
      end

      # since 13.0 it's not possible to disable hashed storage - support can be removed in 14.0
      attrs.delete(:hashed_storage_enabled) if attrs.has_key?(:hashed_storage_enabled)

      attrs = filter_attributes_using_license(attrs)

      unless Feature.enabled?(:logging_field_variant_versioning, :instance)
        attrs.delete(:logging_field_schema_version)
        attrs.delete(:logging_field_dual_emit_target)
      end

      if ApplicationSettings::UpdateService.new(current_settings, current_user, attrs).execute
        present current_settings, with: Entities::ApplicationSetting
      else
        render_validation_error!(current_settings)
      end
    end
  end
end

API::Settings.prepend_mod_with('API::Settings')
