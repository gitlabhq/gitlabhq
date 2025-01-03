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

    desc 'Get the current application settings' do
      success Entities::ApplicationSetting
    end
    get "application/settings" do
      present current_settings, with: Entities::ApplicationSetting
    end

    desc 'Modify application settings' do
      success Entities::ApplicationSetting
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
      optional :container_registry_token_expire_delay, type: Integer, desc: 'Authorization token duration (minutes)'
      optional :decompress_archive_file_timeout, type: Integer, desc: 'Default timeout for decompressing archived files, in seconds. Set to 0 to disable timeouts.'
      optional :default_artifacts_expire_in, type: String, desc: "Set the default expiration time for each job's artifacts"
      optional :default_ci_config_path, type: String, desc: 'The instance default CI/CD configuration file and path for new projects'
      optional :default_project_creation, type: Integer, values: ::Gitlab::Access.project_creation_values, desc: 'Determine if developers can create projects in the group'
      optional :default_branch_protection, type: Integer, values: ::Gitlab::Access.protection_values, desc: 'Determine if developers can push to default branch'
      optional :default_branch_protection_defaults, type: Hash, desc: 'Determine if developers can push to default branch' do
        optional :allowed_to_push, type: Array, desc: 'An array of access levels allowed to push' do
          requires :access_level, type: Integer, values: ProtectedBranch::PushAccessLevel.allowed_access_levels, desc: 'A valid access level'
        end
        optional :allow_force_push, type: Boolean, desc: 'Allow force push for all users with push access.'
        optional :allowed_to_merge, type: Array, desc: 'An array of access levels allowed to merge' do
          requires :access_level, type: Integer, values: ProtectedBranch::MergeAccessLevel.allowed_access_levels, desc: 'A valid access level'
        end
        optional :code_owner_approval_required, type: Boolean, desc: "Require approval from code owners"
        optional :developer_can_initial_push, type: Boolean, desc: 'Allow developers to initial push'
      end
      optional :default_group_visibility, type: String, values: Gitlab::VisibilityLevel.string_values, desc: 'The default group visibility'
      optional :default_project_visibility, type: String, values: Gitlab::VisibilityLevel.string_values, desc: 'The default project visibility'
      optional :default_projects_limit, type: Integer, desc: 'The maximum number of personal projects'
      optional :default_snippet_visibility, type: String, values: Gitlab::VisibilityLevel.string_values, desc: 'The default snippet visibility'
      optional :disable_admin_oauth_scopes, type: Boolean, desc: 'Stop administrators from connecting to non-trusted OAuth applications.'
      optional :disable_feed_token, type: Boolean, desc: 'Disable display of RSS/Atom and Calendar `feed_tokens`'
      optional :disabled_oauth_sign_in_sources, type: Array[String], coerce_with: Validations::Types::CommaSeparatedToArray.coerce, desc: 'Disable certain OAuth sign-in sources'
      optional :domain_denylist_enabled, type: Boolean, desc: 'Enable domain denylist for sign ups'
      optional :domain_denylist, type: Array[String], coerce_with: Validations::Types::CommaSeparatedToArray.coerce, desc: 'Users with e-mail addresses that match these domain(s) will NOT be able to sign-up. Wildcards allowed. Enter multiple entries on separate lines. Ex: domain.com, *.domain.com'
      optional :domain_allowlist, type: Array[String], coerce_with: Validations::Types::CommaSeparatedToArray.coerce, desc: 'ONLY users with e-mail addresses that match these domain(s) will be able to sign-up. Wildcards allowed. Enter multiple entries on separate lines. Ex: domain.com, *.domain.com'
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
      optional :wiki_page_max_content_bytes, type: Integer, desc: "Maximum wiki page content size in bytes"
      optional :wiki_asciidoc_allow_uri_includes, type: Boolean, desc: "Allow URI includes for AsciiDoc wiki pages"
      optional :require_admin_approval_after_user_signup, type: Boolean, desc: 'Require explicit admin approval for new signups'
      optional :whats_new_variant, type: String, values: ApplicationSetting.whats_new_variants.keys, desc: "What's new variant, possible values: `all_tiers`, `current_tier`, and `disabled`."
      optional :floc_enabled, type: Grape::API::Boolean, desc: 'Enable FloC (Federated Learning of Cohorts)'
      optional :user_deactivation_emails_enabled, type: Boolean, desc: 'Send emails to users upon account deactivation'
      optional :suggest_pipeline_enabled, type: Boolean, desc: 'Enable pipeline suggestion banner'
      optional :show_migrate_from_jenkins_banner, type: Boolean, desc: 'Enable Jenkins migration banner'
      optional :enable_artifact_external_redirect_warning_page, type: Boolean, desc: 'Show the external redirect page that warns you about user-generated content in GitLab Pages'
      optional :users_get_by_id_limit, type: Integer, desc: "Maximum number of calls to the /users/:id API per 10 minutes per user. Set to 0 for unlimited requests."
      optional :runner_token_expiration_interval, type: Integer, desc: 'Token expiration interval for shared runners, in seconds'
      optional :group_runner_token_expiration_interval, type: Integer, desc: 'Token expiration interval for group runners, in seconds'
      optional :project_runner_token_expiration_interval, type: Integer, desc: 'Token expiration interval for project runners, in seconds'
      optional :pipeline_limit_per_project_user_sha, type: Integer, desc: "Maximum number of pipeline creation requests allowed per minute per user and commit. Set to 0 for unlimited requests per minute."
      optional :jira_connect_application_key, type: String, desc: "ID of the OAuth application used to authenticate with the GitLab for Jira Cloud app."
      optional :jira_connect_public_key_storage_enabled, type: Boolean, desc: 'Enable public key storage for the GitLab for Jira Cloud app.'
      optional :jira_connect_proxy_url, type: String, desc: "URL of the GitLab instance used as a proxy for the GitLab for Jira Cloud app."
      optional :bulk_import_concurrent_pipeline_batch_limit, type: Integer, desc: 'Maximum simultaneous direct transfer batch exports to process.'
      optional :concurrent_relation_batch_export_limit, type: Integer, desc: 'Maximum number of simultaneous batch export jobs to process.'
      optional :bulk_import_enabled, type: Boolean, desc: 'Enable migrating GitLab groups and projects by direct transfer'
      optional :bulk_import_max_download_file, type: Integer, desc: 'Maximum download file size in MB when importing from source GitLab instances by direct transfer'
      optional :concurrent_github_import_jobs_limit, type: Integer, desc: 'Github Importer maximum number of simultaneous import jobs'
      optional :concurrent_bitbucket_import_jobs_limit, type: Integer, desc: 'Bitbucket Cloud Importer maximum number of simultaneous import jobs'
      optional :concurrent_bitbucket_server_import_jobs_limit, type: Integer, desc: 'Bitbucket Server Importer maximum number of simultaneous import jobs'
      optional :allow_runner_registration_token, type: Boolean, desc: 'Allow registering runners using a registration token'
      optional :ci_max_includes, type: Integer, desc: 'Maximum number of includes per pipeline'
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
      optional :ropc_without_client_credentials, type: Boolean, desc: 'Allows the use of Oauth ROPC flow without client credentials'

      Gitlab::SSHPublicKey.supported_types.each do |type|
        optional :"#{type}_key_restriction",
          type: Integer,
          values: KeyRestrictionValidator.supported_key_restrictions(type),
          desc: "Restrictions on the complexity of uploaded #{type.upcase} keys. A value of #{ApplicationSetting::FORBIDDEN_KEY_VALUE} disables all #{type.upcase} keys."
      end

      use :optional_params_ee

      optional(*Helpers::SettingsHelpers.optional_attributes)
      at_least_one_of(*Helpers::SettingsHelpers.optional_attributes)
    end
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

      if ApplicationSettings::UpdateService.new(current_settings, current_user, attrs).execute
        present current_settings, with: Entities::ApplicationSetting
      else
        render_validation_error!(current_settings)
      end
    end
  end
end

API::Settings.prepend_mod_with('API::Settings')
