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
    route_setting :authorization, permissions: :read_application_setting, boundary_type: :instance,
      assignable_when: [:admin]
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
      optional :admin_mode, type: Boolean, desc: 'If `true`, requires administrators to re-authenticate before performing potentially dangerous administrative operations.'
      optional :admin_notification_email, type: String, desc: 'If set, [abuse reports](https://docs.gitlab.com/administration/review_abuse_reports/) are sent to this address. Abuse reports are always available in the **Admin** area. Deprecated. Use `abuse_notification_email` instead.'
      optional :abuse_notification_email, type: String, desc: 'If set, [abuse reports](https://docs.gitlab.com/administration/review_abuse_reports/) are sent to this address. Abuse reports are always available in the **Admin** area.'
      optional :after_sign_up_text, type: String, desc: 'Text shown after sign up.'
      optional :after_sign_out_path, type: String, desc: 'Users are redirected to this page after they sign out.'
      optional :akismet_enabled, type: Boolean, desc: 'If `true`, helps prevent bots from creating issues. Requires `akismet_api_key`.'
      given akismet_enabled: ->(val) { val } do
        requires :akismet_api_key, type: String, desc: 'Generate API key at http://www.akismet.com'
      end
      optional :asset_proxy_enabled, type: Boolean, desc: 'Enable proxying of assets'
      optional :asset_proxy_url, type: String, desc: 'URL of the asset proxy server'
      optional :asset_proxy_secret_key, type: String, desc: 'Shared secret with the asset proxy server'
      optional :asset_proxy_whitelist, type: Array[String], coerce_with: Validations::Types::CommaSeparatedToArray.coerce, desc: 'Assets that match these domains are not proxied. Wildcards allowed. Your GitLab installation URL is automatically allowlisted. GitLab restart is required to apply changes. Deprecated. Use `asset_proxy_allowlist` instead.'
      optional :asset_proxy_allowlist, type: Array[String], coerce_with: Validations::Types::CommaSeparatedToArray.coerce, desc: 'Assets that match these domains are not proxied. Wildcards allowed. Your GitLab installation URL is automatically allowlisted. GitLab restart is required to apply changes.'
      optional :authn_data_retention_cleanup_enabled, type: Boolean, desc: 'If `true`, runs cleanup workers that permanently delete authentication login history older than one year, and previously revoked OAuth access tokens and grants older than one month. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/579002) in GitLab 18.7.'
      optional :container_registry_token_expire_delay, type: Integer, desc: 'Duration, in minutes, that container registry authorization tokens remain valid.'
      optional :oauth_access_token_expires_in, type: Integer, desc: 'Maximum lifetime in seconds of all new OAuth access tokens issued by the instance. Minimum value: `300` (5 minutes). Default value: `7200` (2 hours). If blank or `null`, uses default value. Does not affect existing OAuth access tokens.'
      optional :decompress_archive_file_timeout, type: Integer, desc: 'Timeout for decompressing archived files, in seconds. Set to `0` to disable the timeout.'
      optional :default_artifacts_expire_in, type: String, desc: "Set the default expiration time for each job's artifacts."
      optional :default_ci_config_path, type: String, desc: 'Default CI/CD configuration file and path for new projects. If empty, new projects use `.gitlab-ci.yml`.'
      optional :default_project_creation, type: Integer, values: ::Gitlab::Access.project_creation_values, desc: 'Default minimum role required to create projects. Can take: `0` _(No one)_, `1` _(Maintainers)_, `2` _(Developers)_, `3` _(Administrators)_, or `4` _(Owners)_.'
      optional :default_branch_protection, type: Integer, values: ::Gitlab::Access.protection_values, desc: 'Level of protection for the default branch. [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/408314) in GitLab 17.0. Use `default_branch_protection_defaults` instead.'
      optional :default_branch_protection_defaults, type: Hash, desc: 'Default branch protection settings. For available options, see [Options for `default_branch_protection_defaults`](https://docs.gitlab.com/api/groups/#options-for-default_branch_protection_defaults). [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/408314) in GitLab 17.0.' do
        optional :allowed_to_push, type: Array, desc: 'Array of access levels allowed to push to the default branch.' do
          # rubocop:disable API/AccessLevelStringType -- Introduced before the cop
          requires :access_level, type: Integer, values: ProtectedBranch::PushAccessLevel.allowed_access_levels, desc: 'Access level allowed to push to the default branch.'
          # rubocop:enable API/AccessLevelStringType
        end
        optional :allow_force_push, type: Boolean, desc: 'If `true`, allows force push for all users with push access.'
        optional :allowed_to_merge, type: Array, desc: 'Array of access levels allowed to merge into the default branch.' do
          # rubocop:disable API/AccessLevelStringType -- Introduced before the cop
          requires :access_level, type: Integer, values: ProtectedBranch::MergeAccessLevel.allowed_access_levels, desc: 'Access level allowed to merge into the default branch.'
          # rubocop:enable API/AccessLevelStringType
        end
        optional :code_owner_approval_required, type: Boolean, desc: "Require approval from code owners"
        optional :developer_can_initial_push, type: Boolean, desc: 'If `true`, allows developers to make the initial push.'
      end
      optional :default_group_visibility, type: String, values: Gitlab::VisibilityLevel.string_values, desc: 'What visibility level new groups receive. Default is `private`. Cannot be set to any levels in `restricted_visibility_levels`.'
      optional :default_project_visibility, type: String, values: Gitlab::VisibilityLevel.string_values, desc: 'What visibility level new projects receive. Default is `private`. Cannot be set to any levels in `restricted_visibility_levels`.'
      optional :default_projects_limit, type: Integer, desc: 'Maximum number of personal projects per user. Default is `100000`.'
      optional :default_snippet_visibility, type: String, values: Gitlab::VisibilityLevel.string_values, desc: 'What visibility level new snippets receive. Default is `private`.'
      optional :dependency_management_settings, type: Hash, desc: 'Dependency management settings. Set `security_update_scheduler_max_concurrency` (integer) to cap the number of security update scheduler jobs that run concurrently across the Sidekiq fleet. Default: `30`. Capped at `200`. Set to `0` to remove the concurrency limit. Ultimate only. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/239173) in GitLab 19.1.' do
        optional :security_update_scheduler_max_concurrency, type: Integer, desc: 'Maximum number of dependency management security update scheduler jobs to run concurrently across the Sidekiq fleet.'
      end
      optional :disable_admin_oauth_scopes, type: Boolean, desc: 'Stop administrators from connecting to non-trusted OAuth applications.'
      optional :disable_feed_token, type: Boolean, desc: 'Disable display of RSS/Atom and Calendar `feed_tokens`'
      optional :disabled_oauth_sign_in_sources, type: Array[String], coerce_with: Validations::Types::CommaSeparatedToArray.coerce, desc: 'OAuth sign-in sources to disable.'
      optional :domain_denylist_enabled, type: Boolean, desc: 'If `true`, enables the domain denylist for sign-ups. Requires `domain_denylist`.'
      optional :domain_denylist, type: Array[String], coerce_with: Validations::Types::CommaSeparatedToArray.coerce, desc: 'Users with e-mail addresses that match these domain(s) will NOT be able to sign-up. Wildcards allowed. Enter multiple entries on separate lines. Ex: domain.com, *.domain.com'
      optional :domain_allowlist, type: Array[String], coerce_with: Validations::Types::CommaSeparatedToArray.coerce, desc: 'Only users with email addresses that match these domains can sign up. Wildcards allowed. For example, `domain.com` or `*.domain.com`. If empty, all domains are allowed.'
      optional :outbound_local_requests_whitelist, type: Array[String], coerce_with: Validations::Types::CommaSeparatedToArray.coerce, desc: 'List of trusted domains or IP addresses to which local requests are allowed when local requests for webhooks and integrations are disabled.'
      optional :email_otp_enabled, type: Boolean, desc: 'If `true`, enables email-based one-time passwords (OTP) as a multi-factor authentication method. Requires `require_email_verification_on_account_locked` to be `true`.'
      optional :iframe_rendering_enabled, type: Boolean, desc: 'If `true`, allows rendering of iframes in Markdown.'
      optional :iframe_rendering_allowlist, type: Array[String], coerce_with: Validations::Types::CommaSeparatedToArray.coerce, desc: 'IDs of embed providers users can embed content from. Enter multiple entries separated by commas or on separate lines.'
      optional :iframe_rendering_allowlist_raw, type: String, desc: 'Raw newline- or comma-separated list of IDs of embed providers users can embed content from.'
      optional :eks_integration_enabled, type: Boolean, desc: 'Enable integration with Amazon EKS'
      given eks_integration_enabled: ->(val) { val } do
        requires :eks_account_id, type: String, desc: 'Amazon account ID for EKS integration.'
        requires :eks_access_key_id, type: String, desc: 'Access key ID for the EKS integration IAM user.'
        requires :eks_secret_access_key, type: String, desc: 'Secret access key for the EKS integration IAM user.'
      end
      optional :email_author_in_body, type: Boolean, desc: 'If `true`, includes the name of the issue, merge request, or comment author in the email body. Useful when email servers do not support overriding the sender name.'
      optional :email_confirmation_setting, type: String, values: ApplicationSetting.email_confirmation_settings.keys, desc: 'Specifies whether users must confirm their email address before signing in. `off` does not require confirmation, `soft` allows sign-in during a confirmation period, and `hard` requires confirmation before sign-in.'
      optional :enabled_git_access_protocol, type: String, values: %w[ssh http all], desc: 'Protocol allowed for Git access. Set to `all` to allow both SSH and HTTP(S).'
      optional :gitpod_enabled, type: Boolean, desc: 'If `true`, enables [Ona integration](https://docs.gitlab.com/integration/gitpod/). Requires `gitpod_url`.'
      given gitpod_enabled: ->(val) { val } do
        requires :gitpod_url, type: String, desc: 'Ona instance URL for the integration.'
      end
      optional :gitaly_timeout_default, type: Integer, desc: 'Default Gitaly timeout, in seconds. Set to `0` to disable timeouts.'
      optional :gitaly_timeout_fast, type: Integer, desc: 'Gitaly fast operation timeout, in seconds. Set to 0 to disable timeouts.'
      optional :gitaly_timeout_medium, type: Integer, desc: 'Medium Gitaly timeout, in seconds. Set to 0 to disable timeouts.'
      optional :grafana_enabled, type: Boolean, desc: 'If `true`, enables Grafana.'
      optional :grafana_url, type: String, desc: 'Grafana URL.'
      optional :gravatar_enabled, type: Boolean, desc: 'If `true`, enables the Gravatar service.'
      optional :help_page_hide_commercial_content, type: Boolean, desc: 'If `true`, hides marketing-related entries from help.'
      optional :help_page_support_url, type: String, desc: 'Alternate support URL for help page and help dropdown.'
      optional :help_page_documentation_base_url, type: String, desc: 'Alternate documentation pages URL.'
      optional :help_page_text, type: String, desc: 'Custom text displayed on the help page.'
      optional :home_page_url, type: String, desc: 'Users who are not signed in are redirected to this page.'
      optional :housekeeping_enabled, type: Boolean, desc: 'Enable automatic repository housekeeping (git repack, git gc)'
      given housekeeping_enabled: ->(val) { val } do
        optional :housekeeping_full_repack_period, type: Integer, desc: 'Number of Git pushes after which a full `git repack` is run. Deprecated. Use `housekeeping_optimize_repository_period` instead.'
        optional :housekeeping_gc_period, type: Integer, desc: 'Number of Git pushes after which `git gc` is run. Deprecated. Use `housekeeping_optimize_repository_period` instead.'
        optional :housekeeping_incremental_repack_period, type: Integer, desc: 'Number of Git pushes after which an incremental `git repack` is run. Deprecated. Use `housekeeping_optimize_repository_period` instead.'

        optional :housekeeping_optimize_repository_period, type: Integer, desc: "Number of Git pushes after which Gitaly is asked to optimize a repository."

        # Requires either all three deprecated attributes (housekeeping_full_repack_period, housekeeping_gc_period, housekeeping_incremental_repack_period) or housekeeping_optimize_repository_period
        all_or_none_of :housekeeping_full_repack_period, :housekeeping_gc_period, :housekeeping_incremental_repack_period
        exactly_one_of :housekeeping_incremental_repack_period, :housekeeping_optimize_repository_period
      end
      optional :html_emails_enabled, type: Boolean, desc: 'If `true`, sends emails in both HTML and plain text formats. If `false`, sends emails in plain text only. Defaults to `true`.'
      optional :import_sources, type: Array[String], coerce_with: Validations::Types::CommaSeparatedToArray.coerce,
        values: %w[github bitbucket bitbucket_server fogbugz git gitlab_project gitea manifest],
        desc: 'Sources to allow project import from. OmniAuth must be configured for GitHub, Bitbucket, and GitLab.com.'
      optional :invisible_captcha_enabled, type: Boolean, desc: 'If `true`, enables Invisible CAPTCHA spam detection during account creation.'
      optional :max_artifacts_size, type: Integer, desc: "Maximum file size, in MB, for each job's artifacts."
      optional :max_attachment_size, type: Integer, desc: 'Maximum attachment size in MB.'
      optional :max_export_size, type: Integer, desc: 'Maximum export size in MB'
      optional :max_github_response_size_limit, type: Integer, desc: 'Maximum size in MB for GitHub API responses. Set to `0` for unlimited size.'
      optional :max_github_response_json_value_count, type: Integer, desc: 'Maximum object count for GitHub API responses. Set to `0` for unlimited. The count is an estimate based on the number of `:`, `,`, `{`, and `[` characters in the response.'
      optional :max_import_size, type: Integer, desc: 'Maximum import size in MB'
      optional :max_import_remote_file_size, type: Integer, desc: 'Maximum remote file size in MB for imports from external object storages'
      optional :max_decompressed_archive_size, type: Integer, desc: 'Maximum decompressed file size for imported archives in MB. Set to `0` for unlimited. Default is `25600`.'
      optional :max_pages_size, type: Integer, desc: 'Maximum size of each GitLab Pages site in MB. Set to `0` to allow up to 1 TB.'
      optional :max_pages_custom_domains_per_project, type: Integer, desc: 'Maximum number of GitLab Pages custom domains per project'
      optional :max_terraform_state_size_bytes, type: Integer, desc: 'Maximum size of the Terraform state file in bytes. Set to `0` for unlimited size.'
      optional :metrics_method_call_threshold, type: Integer, desc: 'Method call is only tracked if it takes longer than this threshold, in milliseconds.'
      optional :password_authentication_enabled, type: Boolean, desc: 'Flag indicating if password authentication is enabled for the web interface' # support legacy names, can be removed in v5
      optional :password_authentication_enabled_for_web, type: Boolean, desc: 'If `true`, enables authentication for the web interface via a GitLab account password. Defaults to `true`.'
      mutually_exclusive :password_authentication_enabled_for_web, :password_authentication_enabled, :signin_enabled
      optional :password_authentication_enabled_for_git, type: Boolean, desc: 'If `true`, enables authentication for Git over HTTP(S) via a GitLab account password. Defaults to `true`.'
      optional :performance_bar_allowed_group_id, type: String, desc: 'Path of the group that is allowed to toggle the performance bar. Deprecated. Use `performance_bar_allowed_group_path` instead.' # support legacy names, can be removed in v6
      optional :performance_bar_allowed_group_path, type: String, desc: 'Path of the group that is allowed to toggle the performance bar.'
      optional :performance_bar_enabled, type: String, desc: 'Deprecated: Pass `performance_bar_allowed_group_path: nil` instead. Allow enabling the performance.' # support legacy names, can be removed in v6
      optional :personal_access_token_prefix, type: String, desc: 'Prefix to prepend to all personal access tokens.'
      optional :require_personal_access_token_expiry, type: Boolean, desc: 'If `true`, requires an expiration date on group and project access tokens, and on personal access tokens not owned by service accounts.'
      optional :kroki_enabled, type: Boolean, desc: 'If `true`, enables [Kroki integration](https://docs.gitlab.com/administration/integration/kroki/). Requires `kroki_url`.'
      given kroki_enabled: ->(val) { val } do
        requires :kroki_url, type: String, desc: 'Kroki server URL.'
      end
      optional :plantuml_enabled, type: Boolean, desc: 'If `true`, enables [PlantUML integration](https://docs.gitlab.com/administration/integration/plantuml/). Requires `plantuml_url`.'
      given plantuml_enabled: ->(val) { val } do
        requires :plantuml_url, type: String, desc: 'The PlantUML server URL'
      end
      optional :diagramsnet_enabled, type: Boolean, desc: 'If `true`, enables [Diagrams.net integration](https://docs.gitlab.com/administration/integration/diagrams_net/). Requires `diagramsnet_url`. Defaults to `true`.'
      given diagramsnet_enabled: ->(val) { val } do
        requires :diagramsnet_url, type: String, desc: 'The Diagrams.net server URL'
      end
      optional :polling_interval_multiplier, type: BigDecimal, desc: 'Interval multiplier used by endpoints that perform polling. Set to `0` to disable polling.'
      optional :project_export_enabled, type: Boolean, desc: 'If `true`, enables project export.'
      optional :prometheus_metrics_enabled, type: Boolean, desc: 'If `true`, enables Prometheus metrics.'
      optional :push_event_hooks_limit, type: Integer, desc: 'Maximum number of changes (branches or tags) in a single push above which webhooks and integrations are not triggered. Setting to `0` does not disable throttling. Default: `3`.'
      optional :push_event_activities_limit, type: Integer, desc: 'Maximum number of changes (branches or tags) in a single push above which a bulk push event is created. Setting to `0` does not disable throttling.'
      optional :recaptcha_enabled, type: Boolean, desc: 'If `true`, enables reCAPTCHA. Requires `recaptcha_private_key` and `recaptcha_site_key`.'
      given recaptcha_enabled: ->(val) { val } do
        requires :recaptcha_site_key, type: String, desc: 'Generate site key at http://www.google.com/recaptcha'
        requires :recaptcha_private_key, type: String, desc: 'Generate private key at http://www.google.com/recaptcha'
      end
      optional :login_recaptcha_protection_enabled, type: Boolean, desc: 'Helps prevent brute-force attacks'
      given login_recaptcha_protection_enabled: ->(val) { val } do
        requires :recaptcha_site_key, type: String, desc: 'Generate site key at http://www.google.com/recaptcha'
        requires :recaptcha_private_key, type: String, desc: 'Generate private key at http://www.google.com/recaptcha'
      end
      optional :repository_checks_enabled, type: Boolean, desc: 'If `true`, GitLab periodically runs `git fsck` in all project and wiki repositories to look for silent disk corruption issues.'
      optional :repository_storages_weighted, type: Hash, coerce_with: Validations::Types::HashOfIntegerValues.coerce, desc: 'Hash of names of storages taken from `gitlab.yml` to [weights](https://docs.gitlab.com/administration/repository_storage_paths/#configure-where-new-repositories-are-stored) ranging from 0 to 100. New projects are created in one of these stores, chosen by a weighted random selection.', documentation: { type: 'Object', additional_properties: Integer }
      optional :require_two_factor_authentication, type: Boolean, desc: 'If `true`, requires all users to set up two-factor authentication. Requires `two_factor_grace_period`.'
      given require_two_factor_authentication: ->(val) { val } do
        requires :two_factor_grace_period, type: Integer, desc: 'Amount of time, in hours, that users can skip enforced two-factor authentication setup.'
      end
      optional :restricted_visibility_levels, type: Array[String], coerce_with: Validations::Types::CommaSeparatedToArray.coerce, desc: 'Selected levels cannot be used by non-administrator users for groups, projects, or snippets. Can take `private`, `internal`, and `public` as a parameter. If the `public` level is restricted, user profiles are only visible to signed-in users. If empty, no levels are restricted. Cannot select levels that are set as `default_project_visibility` and `default_group_visibility`.'
      optional :session_expire_delay, type: Integer, desc: 'Session duration in minutes. Requires a GitLab restart to apply changes.'
      optional :session_expire_from_init, type: Boolean, desc: 'If `true`, sessions expire a number of minutes after the session was created rather than after the last activity. The session lifetime is defined by `session_expire_delay`.'
      optional :shared_runners_enabled, type: Boolean, desc: 'Enable shared runners for new projects'
      given shared_runners_enabled: ->(val) { val } do
        requires :shared_runners_text, type: String, desc: 'Shared runners text '
      end
      optional :valid_runner_registrars, type: Array[String], desc: "List of types which are allowed to register a GitLab Runner. Can be `[]`, `['group']`, `['project']`, or `['group', 'project']`."
      optional :signin_enabled, type: Boolean, desc: 'If `true`, enables password authentication for the web interface. Deprecated. Use `password_authentication_enabled_for_web` instead.' # support legacy names, can be removed in v5
      optional :signup_enabled, type: Boolean, desc: 'If `true`, enables registration. Defaults to `true`.'
      optional :sourcegraph_enabled, type: Boolean, desc: 'If `true`, enables Sourcegraph integration. Requires `sourcegraph_url`.'
      optional :sourcegraph_public_only, type: Boolean, desc: 'If `true`, blocks Sourcegraph from being loaded on private and internal projects. Defaults to `true`.'
      given sourcegraph_enabled: ->(val) { val } do
        requires :sourcegraph_url, type: String, desc: 'Configured Sourcegraph instance URL.'
      end
      optional :spam_check_endpoint_enabled, type: Boolean, desc: 'Enable Spam Check via external API endpoint'
      given spam_check_endpoint_enabled: ->(val) { val } do
        requires :spam_check_endpoint_url, type: String, desc: 'URL of the external Spamcheck service endpoint. Valid URI schemes are `grpc` or `tls`. Specifying `tls` forces communication to be encrypted.'
      end
      optional :terminal_max_session_time, type: Integer, desc: 'Maximum time for a web terminal WebSocket connection, in seconds. Set to `0` for unlimited time.'
      optional :usage_ping_enabled, type: Boolean, desc: 'Every week GitLab will report license usage back to GitLab, Inc.'
      optional :local_markdown_version, type: Integer, desc: 'Local Markdown version. Increase this value to invalidate all cached Markdown.'
      optional :allow_local_requests_from_hooks_and_services, type: Boolean, desc: 'If `true`, allows requests to the local network from webhooks and integrations. Deprecated. Use `allow_local_requests_from_web_hooks_and_services` instead.' # support legacy names, can be removed in v5
      optional :mailgun_events_enabled, type: Grape::API::Boolean, desc: 'Enable Mailgun event receiver'
      given mailgun_events_enabled: ->(val) { val } do
        requires :mailgun_signing_key, type: String, desc: 'Mailgun HTTP webhook signing key for receiving events from webhook.'
      end
      optional :snowplow_enabled, type: Grape::API::Boolean, desc: 'Enable Snowplow tracking'
      given snowplow_enabled: ->(val) { val } do
        requires :snowplow_collector_hostname, type: String, desc: 'The Snowplow collector hostname'
        optional :snowplow_cookie_domain, type: String, desc: 'Snowplow cookie domain, for example `.gitlab.com`.'
        optional :snowplow_app_id, type: String, desc: 'Snowplow site name or application ID, for example `gitlab`.'
      end
      optional :issues_create_limit, type: Integer, desc: "Maximum number of issue creation requests allowed per minute per user. Set to 0 for unlimited requests per minute."
      optional :raw_blob_request_limit, type: Integer, desc: 'Maximum number of requests per minute for each raw path (default is `300`). Set to `0` to disable throttling.'
      optional :raw_blob_request_limit_unauthenticated, type: Integer, desc: 'Maximum number of unauthenticated requests per minute across all raw paths in a project (default is `800`). Set to `0` to disable throttling.'
      optional :wiki_page_max_content_bytes, type: Integer, desc: 'Maximum wiki page content size in bytes. Default: 5242880 bytes (5 MB). The minimum value is 1024 bytes.'
      optional :description_and_note_max_size, type: Integer, desc: 'Maximum work item, merge request, and vulnerability description and comment content size in bytes.'
      optional :wiki_asciidoc_allow_uri_includes, type: Boolean, desc: 'If `true`, allows URI includes for AsciiDoc wiki pages.'
      optional :require_admin_approval_after_user_signup, type: Boolean, desc: 'If `true`, requires explicit administrator approval for new signups.'
      optional :whats_new_variant, type: String, values: ApplicationSetting.whats_new_variants.keys, desc: "Which features [What's new](https://docs.gitlab.com/administration/whats-new/) shows. `all_tiers` shows features for all tiers, `current_tier` shows only features for the instance's tier, and `disabled` hides What's new."
      optional :floc_enabled, type: Grape::API::Boolean, desc: 'If `true`, enables FloC (Federated Learning of Cohorts).'
      optional :user_deactivation_emails_enabled, type: Boolean, desc: 'If `true`, sends emails to users when their account is deactivated.'
      optional :show_migrate_from_jenkins_banner, type: Boolean, desc: 'If `true`, shows the Jenkins migration banner.'
      optional :enable_artifact_external_redirect_warning_page, type: Boolean, desc: 'If `true`, shows the external redirect page that warns about user-generated content in GitLab Pages.'
      optional :users_get_by_id_limit, type: Integer, desc: 'Maximum number of calls to the `/users/:id` API per 10 minutes per user. Set to `0` for unlimited requests.'
      optional :runner_token_expiration_interval, type: Integer, desc: 'Set the expiration time (in seconds) of authentication tokens of newly registered instance runners. Minimum value is 7200 seconds. For more information, see [Automatically rotate authentication tokens](https://docs.gitlab.com/ci/runners/configure_runners/#automatically-rotate-runner-authentication-tokens).'
      optional :group_runner_token_expiration_interval, type: Integer, desc: 'Set the expiration time (in seconds) of authentication tokens of newly registered group runners. Minimum value is 7200 seconds. For more information, see [Automatically rotate authentication tokens](https://docs.gitlab.com/ci/runners/configure_runners/#automatically-rotate-runner-authentication-tokens).'
      optional :project_runner_token_expiration_interval, type: Integer, desc: 'Set the expiration time (in seconds) of authentication tokens of newly registered project runners. Minimum value is 7200 seconds. For more information, see [Automatically rotate authentication tokens](https://docs.gitlab.com/ci/runners/configure_runners/#automatically-rotate-runner-authentication-tokens).'
      optional :pipeline_limit_per_project_user_sha, type: Integer, desc: 'Maximum number of pipeline creation requests per minute per user and commit. Set to `0` for unlimited requests. Disabled by default.'
      optional :pipeline_limit_per_user, type: Integer, desc: 'Maximum number of pipeline creation requests allowed per minute per user. Set to `0` for unlimited requests.'
      optional :ci_lint_limit_per_user, type: Integer, desc: 'Maximum number of CI Lint requests per minute per user. Set to `0` for unlimited requests. Disabled by default.'
      optional :jira_connect_application_key, type: String, desc: "ID of the OAuth application used to authenticate with the GitLab for Jira Cloud app."
      optional :jira_connect_public_key_storage_enabled, type: Boolean, desc: 'If `true`, enables public key storage for the GitLab for Jira Cloud app.'
      optional :jira_connect_proxy_url, type: String, desc: "URL of the GitLab instance used as a proxy for the GitLab for Jira Cloud app."
      optional :jira_forge_app_id, type: String, desc: "Atlassian Forge app ID (ARI) of the GitLab for Jira Cloud app, used to verify inbound Forge Invocation Tokens."
      optional :bulk_import_concurrent_pipeline_batch_limit, type: Integer, desc: 'Maximum number of simultaneous direct transfer batch exports to process.'
      optional :concurrent_relation_batch_export_limit, type: Integer, desc: 'Maximum number of simultaneous batch export jobs to process.'
      optional :bulk_import_enabled, type: Boolean, desc: 'If `true`, enables migrating GitLab groups and projects by direct transfer.'
      optional :bulk_import_max_download_file, type: Integer, desc: 'Maximum download file size, in MB, when importing from source GitLab instances by direct transfer.'
      optional :autocomplete_users_limit, type: Integer, desc: 'Maximum number of authenticated requests per minute per user to the users autocomplete endpoint.'
      optional :autocomplete_users_unauthenticated_limit, type: Integer, desc: 'Maximum number of unauthenticated requests per minute per IP address to the users autocomplete endpoint.'
      optional :concurrent_github_import_jobs_limit, type: Integer, desc: 'Maximum number of simultaneous import jobs for the GitHub importer. Default is `1000`.'
      optional :concurrent_bitbucket_import_jobs_limit, type: Integer, desc: 'Maximum number of simultaneous import jobs for the Bitbucket Cloud importer. Default is `100`.'
      optional :concurrent_bitbucket_server_import_jobs_limit, type: Integer, desc: 'Maximum number of simultaneous import jobs for the Bitbucket Server importer. Default is `100`.'
      optional :concurrent_pull_request_import_jobs_limit, type: Integer, desc: 'Maximum number of simultaneous pull request import jobs for the GitHub, Bitbucket Cloud, and Bitbucket Server importers. Default is `200`.'
      optional :allow_runner_registration_token, type: Boolean, desc: 'If `true`, allows using a registration token to create a runner. Defaults to `true`.'
      optional :ci_max_includes, type: Integer, desc: '[Maximum number of includes](https://docs.gitlab.com/administration/cicd/limits/#maximum-number-of-includes) per pipeline. Default is `150`.'
      optional :ci_max_caches_per_job, type: Integer, desc: 'Maximum number of caches that can be defined in a single CI/CD job.'
      optional :ci_job_live_trace_enabled, type: Boolean, desc: 'If `true`, turns on incremental logging for job logs. Archived job logs are incrementally uploaded to object storage, which must be configured.'
      optional :ci_job_trace_update_interval, type: Integer, desc: 'Job log update interval when the job log is not open, in seconds.'
      optional :ci_job_trace_update_interval_when_being_watched, type: Integer, desc: 'Job log update interval when the job log is open, in seconds.'
      optional :git_push_pipeline_limit, type: Integer, desc: 'Maximum number of branch or tag pipelines that can be triggered by a single Git push. Set to `0` to disable the limit.'
      optional :security_policy_global_group_approvers_enabled, type: Boolean, desc: 'If `true`, looks up merge request approval policy approval groups globally. If `false`, looks them up within project hierarchies.'
      optional :slack_app_enabled, type: Grape::API::Boolean, desc: 'If `true`, enables the GitLab for Slack app. Requires `slack_app_id`, `slack_app_secret`, `slack_app_signing_secret`, and `slack_app_verification_token`.'
      given slack_app_enabled: ->(val) { val } do
        requires :slack_app_id, type: String, desc: 'Client ID of the GitLab for Slack app.'
        requires :slack_app_secret, type: String, desc: 'Client secret of the GitLab for Slack app. Used for authenticating OAuth requests from the app.'
        requires :slack_app_signing_secret, type: String, desc: 'Signing secret of the GitLab for Slack app. Used for authenticating API requests from the app.'
        requires :slack_app_verification_token, type: String, desc: 'Verification token of the GitLab for Slack app. This method of authentication is deprecated by Slack and used only for authenticating slash commands from the app.'
      end
      optional :namespace_aggregation_schedule_lease_duration_in_seconds, type: Integer, desc: 'Maximum duration, in seconds, between refreshes of namespace statistics. Defaults to `300`.'
      optional :project_jobs_api_rate_limit, type: Integer, desc: 'Maximum authenticated requests to /project/:id/jobs per minute'
      optional :security_txt_content, type: String, desc: 'Public security contact information made available at https://gitlab.example.com/.well-known/security.txt.'
      optional :downstream_pipeline_trigger_limit_per_project_user_sha, type: Integer, desc: '[Maximum number of downstream pipelines](https://docs.gitlab.com/administration/cicd/limits/#limit-downstream-pipeline-trigger-rate) that can be triggered per minute for a given project, user, and commit. Default: `0` (no restriction).'
      optional :pipeline_cancel_limit_per_user_project, type: Integer, desc: 'Maximum number of pipeline cancellations allowed per minute for a given project.'
      optional :pipeline_retry_limit_per_user_project, type: Integer, desc: 'Maximum number of pipeline retries allowed per minute for a given project.'
      optional :job_retry_limit_per_user_project, type: Integer, desc: 'Maximum number of job retries allowed per minute for a given project.'
      optional :job_play_limit_per_user_project, type: Integer, desc: 'Maximum number of manual job runs allowed per minute for a given project.'
      optional :pipeline_delete_limit_per_user_project, type: Integer, desc: 'Maximum number of pipeline deletions allowed per minute for a given project.'
      optional :ai_action_api_rate_limit, type: Integer, desc: 'Maximum requests a user can make per 8 hours to aiAction endpoint'
      optional :code_suggestions_api_rate_limit, type: Integer, desc: 'Maximum number of requests a user can make to the code suggestions endpoint per minute.'
      optional :resource_usage_limits, type: JSON, desc: 'Definition for resource usage limits enforced in Sidekiq workers.'
      optional :code_dropdown_custom_clients, type: Array, desc: 'Custom "Open with" clients shown in the project Code dropdown list' do
        requires :name, type: String, desc: 'Name shown to users in the Code dropdown list'
        optional :ssh_url_template, type: String, desc: 'URL template opened for the SSH clone URL. Must contain {url} exactly once'
        optional :http_url_template, type: String, desc: 'URL template opened for the HTTPS clone URL. Must contain {url} exactly once'
      end
      optional :vscode_extension_marketplace, type: Hash, desc: 'Settings for VS Code Extension Marketplace.' do
        optional :enabled, type: Boolean, desc: 'If `true`, enables the VS Code extension marketplace for the Web IDE and Workspaces.'
        optional :preset, type: String, desc: "The preset configuration of URL's for the VS Code Extension Marketplace"
        optional :custom_values, type: Hash, desc: "VS Code Extension Marketplace URL's when preset is 'custom'"
      end
      optional :enable_language_server_restrictions, type: Boolean, desc: 'Enables enforcing language server restrictions'
      optional :minimum_language_server_version, type: String, desc: 'Minimum language server version to accept requests from.'
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
        desc: 'If `true`, allows users to delete their accounts. Premium and Ultimate only.'
      optional :allow_application_default_credentials_for_offline_transfer,
        desc: 'If `true`, allows Google Cloud Application Default Credentials for offline transfer. Even when enabled, only administrators can use these credentials, and the bucket name must start with `gitlab-offline-transfer-`. Has no effect on GitLab.com. For more information, see [Allow application default credentials for offline transfer](https://docs.gitlab.com/administration/settings/import_and_export_settings/#allow-application-default-credentials-for-offline-transfer). [Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/602489) in GitLab 19.3.'
      optional :allow_bypass_placeholder_confirmation,
        desc: 'If `true`, skips confirmation when administrators reassign placeholder users. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/534330) in GitLab 18.0.'
      optional :allow_local_requests_from_system_hooks, desc: 'If `true`, allows requests to the local network from system hooks.'
      optional :allow_local_requests_from_web_hooks_and_services,
        desc: 'If `true`, allows requests to the local network from webhooks and integrations.'
      optional :allow_project_creation_for_guest_and_below,
        desc: 'If `true`, users assigned up to the Guest role can create groups and personal projects. Defaults to `true`.'
      optional :allow_s3_compatible_storage_for_offline_transfer,
        desc: 'If `true`, allows S3-compatible object storage for offline transfer. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/579705) in GitLab 18.9.'
      optional :archive_builds_in_human_readable,
        desc: 'Set the duration for which the jobs are considered as old and expired. After that time passes, the ' \
          'jobs are archived and no longer able to be retried. Make it empty to never expire jobs. It has to be no ' \
          'less than 1 day, for example: `15 days`, `1 month`, `2 years`.'
      optional :asciidoc_max_includes,
        desc: 'Maximum number of AsciiDoc include directives processed in any one document. Default: `32`. Maximum: `64`.'
      optional :authorized_keys_enabled,
        desc: 'If `true`, GitLab uses the `authorized_keys` file to authenticate SSH keys, which supports Git over SSH without additional configuration. Disable only if you have configured your OpenSSH server to use `AuthorizedKeysCommand`. Defaults to `true`.'
      optional :auto_accept_awarded_achievements,
        desc: 'If `true`, newly awarded achievements are accepted automatically and appear on user profiles ' \
          'immediately. Does not affect achievements awarded before this setting is enabled. Recipients can still ' \
          'hide any achievement. Default value: `false`. ' \
          '[Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/607750) in GitLab 19.4.'
      optional :auto_devops_domain,
        desc: "Specify a domain to use by default for every project's Auto Review Apps and Auto Deploy stages."
      optional :auto_devops_enabled,
        desc: 'If `true`, enables Auto DevOps for projects by default. Auto DevOps automatically builds, tests, and deploys applications based on a predefined CI/CD configuration.'
      optional :bulk_import_max_download_file_size,
        desc: 'Maximum download file size when importing from source GitLab instances by direct transfer.'
      optional :can_create_group, desc: 'If `true`, users can create top-level groups. Defaults to `true`.'
      optional :ci_delete_pipelines_in_seconds_limit_human_readable,
        desc: 'Maximum value that is allowed for configuring pipeline retention. Defaults to `1 year`.'
      optional :ci_max_total_yaml_size_bytes,
        desc: 'Maximum amount of memory, in bytes, that can be allocated for the pipeline configuration, with all included YAML configuration files.'
      optional :ci_partitions_in_seconds_limit,
        desc: 'Time window, in seconds, before new CI partitions are created and the system switches to the next set of partitions. Must be between 1 month and 6 months. Default is 1 month (`2592000`). Write-only. Not returned in GET responses. Deprecated. Use `ci_partitions_in_seconds_limit_human_readable` instead. Scheduled for removal in API v5.'
      optional :ci_partitions_in_seconds_limit_human_readable,
        desc: 'Time window before new CI partitions are created and the system switches to the next set of partitions. Must be between `1 month` and `6 months`. Defaults to `1 month`.'
      optional :commit_email_hostname, desc: 'Custom hostname (for private commit emails).'
      optional :container_expiration_policies_enable_historic_entries, desc: 'If `true`, enables [cleanup policies](https://docs.gitlab.com/user/packages/container_registry/reduce_container_registry_storage/#enable-the-cleanup-policy) for all projects.'
      optional :container_registry_cleanup_tags_service_max_list_size,
        desc: 'Maximum number of tags that can be deleted in a single execution of [cleanup policies](https://docs.gitlab.com/user/packages/container_registry/reduce_container_registry_storage/#set-cleanup-limits-to-conserve-resources).'
      optional :container_registry_delete_tags_service_timeout,
        desc: 'Maximum time, in seconds, that the cleanup process can take to delete a batch of tags for [cleanup policies](https://docs.gitlab.com/user/packages/container_registry/reduce_container_registry_storage/#set-cleanup-limits-to-conserve-resources).'
      optional :container_registry_expiration_policies_caching,
        desc: 'If `true`, enables caching during the execution of [cleanup policies](https://docs.gitlab.com/user/packages/container_registry/reduce_container_registry_storage/#set-cleanup-limits-to-conserve-resources).'
      optional :container_registry_expiration_policies_worker_capacity, desc: 'Number of workers for [cleanup policies](https://docs.gitlab.com/user/packages/container_registry/reduce_container_registry_storage/#set-cleanup-limits-to-conserve-resources).'
      optional :custom_http_clone_url_root, desc: 'Set a custom Git clone URL for HTTP(S).'
      optional :default_branch_name, desc: '[Set the initial branch name](https://docs.gitlab.com/user/project/repository/branches/default/#change-the-default-branch-name-for-new-projects-in-an-instance) for all projects in an instance.'
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
      optional :diff_max_commits, desc: 'Maximum number of [diff commits](https://docs.gitlab.com/administration/diff_limits/) per merge request.'
      optional :diff_max_files, desc: 'Maximum number of [files in a diff](https://docs.gitlab.com/administration/diff_limits/).'
      optional :diff_max_lines, desc: 'Maximum number of [lines in a diff](https://docs.gitlab.com/administration/diff_limits/).'
      optional :diff_max_patch_bytes, desc: 'Maximum [diff patch size](https://docs.gitlab.com/administration/diff_limits/), in bytes.'
      optional :diff_max_versions, desc: 'Maximum number of [diff versions](https://docs.gitlab.com/administration/diff_limits/) per merge request.'
      optional :disable_password_authentication_for_users_with_sso_identities,
        desc: 'Disable password authentication in the web interface for users with an SSO identity. This does not ' \
          'affect Git operations over HTTP(S). Default is `false`.'
      optional :dns_rebinding_protection_enabled, desc: 'If `true`, enforces DNS-rebinding attack protection.'
      optional :email_restrictions,
        desc: 'Regular expression that is checked against the email used during registration.'
      optional :email_restrictions_enabled, desc: 'If `true`, prevents new users from signing up with an email address that matches the `email_restrictions` regular expression.'
      optional :enforce_terms, desc: 'If `true`, enforces the application terms of service for all users. Requires `terms`.'
      optional :external_auth_client_cert,
        desc: 'Certificate to use to authenticate with the external authorization service. Requires `external_auth_client_key`.'
      optional :external_auth_client_key,
        desc: 'Private key for the certificate when authentication is required for the external authorization service. Encrypted when stored.'
      optional :external_auth_client_key_pass,
        desc: 'Passphrase to use for the private key when authenticating with the external authorization service. Encrypted when stored.'
      optional :external_authorization_service_default_label,
        desc: 'Default classification label to use when requesting authorization and no classification label has been specified on the project.'
      optional :external_authorization_service_enabled,
        desc: 'If `true`, uses an external authorization service for accessing projects. Requires `external_authorization_service_default_label`, `external_authorization_service_timeout`, and `external_authorization_service_url`.'
      optional :external_authorization_service_timeout,
        desc: 'The timeout after which an authorization request is aborted, in seconds. When a request times out, ' \
          'access is denied to the user. (min: 0.001, max: 10, step: 0.001).'
      optional :external_authorization_service_url, desc: 'URL to which authorization requests are directed.'
      optional :external_pipeline_validation_service_timeout,
        desc: 'Time to wait for a response from the pipeline validation service, in seconds. Assumes `OK` if it times out.'
      optional :external_pipeline_validation_service_token,
        desc: 'Token to include as the `X-Gitlab-Token` header in requests to the URL in `external_pipeline_validation_service_url`.'
      optional :external_pipeline_validation_service_url, desc: 'URL to use for pipeline validation requests.'
      optional :failed_login_attempts_unlock_period_in_minutes,
        desc: 'Time period in minutes after which the user is unlocked when maximum number of failed sign-in ' \
          'attempts reached.'
      optional :first_day_of_week,
        desc: 'Start day of the week for calendar views and date pickers. Valid values are `0` (default) for Sunday, ' \
          '`1` for Monday, and `6` for Saturday.'
      optional :gitlab_dedicated_instance, desc: 'If `true`, the instance was provisioned for GitLab Dedicated.'
      optional :gitlab_environment_toolkit_instance,
        desc: 'If `true`, the instance was provisioned with the GitLab Environment Toolkit for Service Ping reporting.'
      optional :gitlab_product_usage_data_enabled,
        desc: 'If `true`, product usage data collection is enabled. When the `GITLAB_PRODUCT_USAGE_DATA_ENABLED` environment variable is set, the API returns the effective value from the environment variable.'
      optional :gitlab_shell_operation_limit,
        desc: 'Maximum number of Git operations per minute a user can perform. Default: `600`.'
      optional :hashed_storage_enabled,
        desc: 'Create new projects using hashed storage paths: Enable immutable, hash-based paths and repository ' \
          'names to store repositories on disk. This prevents repositories from having to be moved or renamed when ' \
          'the Project URL changes and may improve disk I/O performance. (Always enabled in GitLab versions 13.0 and ' \
          'later, configuration is scheduled for removal in 14.0)'
      optional :hide_third_party_offers, desc: 'If `true`, hides offers from third parties in GitLab.'
      optional :inactive_projects_delete_after_months,
        desc: 'If `delete_inactive_projects` is `true`, the time (in months) to wait before deleting dormant ' \
          'projects. Default is `2`.'
      optional :inactive_projects_min_size_mb,
        desc: 'If `delete_inactive_projects` is `true`, the minimum repository size, in MB, for projects to be checked for inactivity. Default is `0`.'
      optional :inactive_projects_send_warning_email_after_months,
        desc: 'If `delete_inactive_projects` is `true`, sets the time (in months) to wait before emailing ' \
          'Maintainers that the project is scheduled to be deleted because it is dormant. Default is `1`.'
      optional :inactive_resource_access_tokens_delete_after_days,
        desc: 'Specifies retention period for inactive project and group access tokens. Default is `30`.'
      optional :include_optional_metrics_in_service_ping,
        desc: 'If `true`, enables optional metrics in Service Ping.'
      optional :keep_latest_artifact,
        desc: 'If `true`, prevents the deletion of the artifacts from the most recent successful jobs, regardless of the expiry time. Defaults to `true`.'
      optional :kroki_diagram_proxy_enabled, desc: 'Enable Kroki diagram proxy. Default is `false`.'
      optional :kroki_formats,
        desc: 'Additional formats supported by the Kroki instance. Possible values are `true` or `false` for formats ' \
          '`bpmn`, `blockdiag`, `excalidraw`, and `mermaid` in the format `<format>: true` or `<format>: false`.'
      optional :lock_require_sha_for_merge,
        desc: 'If `true`, enforces the `require_sha_for_merge` setting for all groups on the instance. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/236732) in GitLab 19.2.'
      optional :max_http_decompressed_size,
        desc: 'Maximum allowed size in MiB for Gzip-compressed HTTP responses from outbound requests after decompression. Set to `0` for unlimited.'
      optional :max_http_response_csv_structural_chars,
        desc: 'Maximum allowed object count in CSV HTTP responses from outbound requests. Count is an estimate based ' \
          'on the number of `,`, `;`, `\t`, and `\n` occurrences in the response. Introduced in GitLab 18.4.'
      optional :max_http_response_json_depth,
        desc: 'Maximum allowed nesting depth in JSON HTTP responses from outbound requests.'
      optional :max_http_response_json_structural_chars,
        desc: 'Maximum allowed object count in JSON HTTP responses from outbound requests. Count is an estimate ' \
          'based on the number of `:`, `,`, `{`, and `[` occurrences in the response. Introduced in GitLab 18.4.'
      optional :max_http_response_size_limit,
        desc: 'Maximum allowed size in MiB for HTTP responses from outbound requests. Set to `0` for unlimited. Applicable for integrations, importers, and webhooks. Introduced in GitLab 18.4.'
      optional :max_http_response_xml_structural_chars,
        desc: 'Maximum allowed object count in XML HTTP responses from outbound requests. Count is an estimate based ' \
          'on the number of `<`, and `=` occurrences in the response. Introduced in GitLab 18.4.'
      optional :max_login_attempts, desc: 'Maximum number of sign-in attempts before locking out the user.'
      optional :max_yaml_depth,
        desc: 'Maximum depth of nested CI/CD configuration added with the [`include` keyword](https://docs.gitlab.com/ci/yaml/#include). Default: `100`.'
      optional :max_yaml_size_bytes,
        desc: 'Maximum size in bytes of a single CI/CD configuration file. Default: `2097152`.'
      optional :minimum_password_length,
        desc: 'Indicates whether passwords require a minimum length. Premium and Ultimate only.'
      optional :mirror_available,
        desc: 'If `true`, project Maintainers can configure repository mirroring. If `false`, only administrators can configure repository mirroring.'
      optional :notify_on_unknown_sign_in,
        desc: 'If `true`, sends a notification when a sign-in from an unknown IP address occurs.'
      optional :offline_transfer_exports_enabled,
        desc: 'If `true`, enables exporting GitLab groups and projects by offline transfer. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/588971) in GitLab 19.3.'
      optional :offline_transfer_imports_enabled,
        desc: 'If `true`, enables importing GitLab groups and projects by offline transfer. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/588971) in GitLab 19.3.'
      optional :package_registry_allow_anyone_to_pull_option,
        desc: 'If `true`, makes the option to [allow anyone to pull from the package registry](https://docs.gitlab.com/user/packages/package_registry/#allow-anyone-to-pull-from-package-registry) visible and changeable in project settings.'
      optional :package_registry_cleanup_policies_worker_capacity,
        desc: 'Number of workers assigned to the packages cleanup policies.'
      optional :pages_domain_verification_enabled,
        desc: 'If `true`, requires users to prove ownership of custom domains. Domain verification is an essential security measure for public GitLab sites. Users are required to demonstrate they control a domain before it is enabled.'
      optional :pages_unique_domain_default_enabled,
        desc: 'If `true`, enables unique domains by default for Pages sites to avoid cookie sharing between sites under a given namespace. Defaults to `true`.'
      optional :plantuml_diagram_proxy_enabled, desc: 'Enable PlantUML diagram proxy. Default is `false`.'
      optional :projects_api_rate_limit_unauthenticated,
        desc: 'Maximum number of requests per 10 minutes per IP address for unauthenticated requests to the [list all projects API](https://docs.gitlab.com/api/projects/#list-all-projects). Default: `400`. To disable throttling, set to `0`.'
      optional :protected_ci_variables, desc: 'If `true`, CI/CD variables are protected by default.'
      optional :rate_limiting_response_text,
        desc: 'When rate limiting is enabled via the `throttle_*` settings, send this plain text response when a rate limit is exceeded. `Retry later` is sent if this is blank.'
      optional :receive_max_input_size, desc: 'Maximum push size (MB).'
      optional :relation_export_batch_size,
        desc: 'Size of each batch when exporting batched relations. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/194607) in GitLab 18.2.'
      optional :remember_me_enabled, desc: 'If `true`, enables the [**Remember me** setting](https://docs.gitlab.com/administration/settings/account_and_limit_settings/#configure-the-remember-me-option).'
      optional :require_admin_two_factor_authentication,
        desc: 'Allow administrators to require 2FA for all administrators on the instance.'
      optional :require_email_verification_on_account_locked,
        desc: 'If `true`, all users on the instance must verify their identity after suspicious sign-in activity is ' \
          'detected.'
      optional :require_sha_for_merge,
        desc: 'If `true`, requires a valid commit `sha` for calls to the [merge a merge request](https://docs.gitlab.com/api/merge_requests/#merge-a-merge-request) endpoint. Sets the instance default. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/236732) in GitLab 19.2.'
      optional :runner_jobs_endpoints_api_limit,
        desc: 'Maximum number of requests per minute per job token for requests to the `/jobs/*` runner jobs API endpoints. Default: `200`. To disable throttling, set to `0`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/462537) in GitLab 18.5.'
      optional :runner_jobs_patch_trace_api_limit,
        desc: 'Maximum number of requests per minute per runner token for requests to the `PATCH /jobs/:id/trace` ' \
          'runner jobs API endpoint. Default: 2000. To disable throttling, set to 0. ' \
          '[Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/462537) in GitLab 18.5.'
      optional :runner_jobs_request_api_limit,
        desc: 'Maximum number of requests per minute per runner token for requests to the `/jobs/request` runner jobs API endpoint. Default: `2000`. To disable throttling, set to `0`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/462537) in GitLab 18.5.'
      optional :search_rate_limit,
        desc: 'Maximum number of requests per minute for performing a search while authenticated. Default: `30`. To disable throttling, set to `0`.'
      optional :search_rate_limit_unauthenticated,
        desc: 'Maximum number of requests per minute for performing a search while unauthenticated. Default: `10`. To disable throttling, set to `0`.'
      optional :sidekiq_job_limiter_compression_threshold_bytes,
        desc: 'Threshold in bytes at which Sidekiq jobs are compressed before being stored in Redis. Default: 100,000 bytes (100 KB).'
      optional :sidekiq_job_limiter_limit_bytes,
        desc: "Threshold in bytes at which Sidekiq jobs are rejected. Default: 0 bytes (doesn't reject any job)."
      optional :sidekiq_job_limiter_mode,
        values: ::ApplicationSetting.sidekiq_job_limiter_modes.keys,
        desc: "Sets the behavior for Sidekiq job size limits. Default: 'compress'."
      optional :sidekiq_timezone_override,
        desc: 'IANA timezone identifier (for example, `America/Chicago`) applied to all Sidekiq cron jobs. When ' \
          'blank, no override is applied and cron jobs use the Rails application timezone.'
      optional :sign_in_restrictions, desc: 'Application sign in restrictions.'
      optional :silent_admin_exports_enabled, desc: 'If `true`, enables [Silent administrator exports](https://docs.gitlab.com/administration/settings/import_and_export_settings/#enable-silent-admin-exports). Default is `false`.'
      optional :silent_mode_enabled, desc: 'If `true`, enables [Silent mode](https://docs.gitlab.com/administration/silent_mode/). Default is `false`.'
      optional :snippet_size_limit, desc: 'Maximum snippet content size in bytes. Default: 52428800 bytes (50 MB).'
      optional :snowplow_database_collector_hostname,
        desc: 'The Snowplow collector for database events hostname. (for example, `your-db-snowplow-collector.example.com`)'
      optional :spam_check_api_key, desc: 'API key used by GitLab for accessing the Spam Check service endpoint.'
      optional :static_objects_external_storage_auth_token,
        desc: 'Authentication token for the external storage linked in `static_objects_external_storage_url`.'
      optional :static_objects_external_storage_url, desc: 'URL to an external storage for repository static objects.'
      optional :terms, desc: '(**Required by**: `enforce_terms`) Markdown content for the ToS.'
      optional :throttle_authenticated_api_enabled,
        desc: 'If `true`, enables the authenticated API request rate limit. Helps reduce request volume (for example, from crawlers or abusive bots). Requires `throttle_authenticated_api_period_in_seconds` and `throttle_authenticated_api_requests_per_period`.'
      optional :throttle_authenticated_api_period_in_seconds, desc: 'Rate limit period in seconds.'
      optional :throttle_authenticated_api_requests_per_period, desc: 'Maximum requests per period per user.'
      optional :throttle_authenticated_git_http_enabled,
        desc: 'If `true`, enforces the authenticated Git HTTP request rate limit. Default value: `false`.'
      optional :throttle_authenticated_git_http_period_in_seconds,
        desc: 'Rate limit period in seconds. `throttle_authenticated_git_http_enabled` must be `true`. Default ' \
          'value: `3600`.'
      optional :throttle_authenticated_git_http_requests_per_period,
        desc: 'Maximum requests per period per user. `throttle_authenticated_git_http_enabled` must be `true`. ' \
          'Default value: `3600`.'
      optional :throttle_authenticated_mcp_enabled,
        desc: 'If `true`, enforces the rate limit on requests to the MCP Server endpoint, ' \
          '`/api/v4/mcp`, for any HTTP method. Does not apply to other MCP endpoints. ' \
          'Default value: `false`.'
      optional :throttle_authenticated_mcp_period_in_seconds,
        desc: 'Rate limit period in seconds. `throttle_authenticated_mcp_enabled` must be `true`. Default value: `60`.'
      optional :throttle_authenticated_mcp_requests_per_period,
        desc: 'Maximum requests per period per user. `throttle_authenticated_mcp_enabled` must be `true`. Default ' \
          'value: `600`.'
      optional :throttle_authenticated_dependency_proxy_enabled,
        desc: 'If `true`, enforces the authenticated dependency proxy request rate limit. Default value: `false`.'
      optional :throttle_authenticated_dependency_proxy_period_in_seconds,
        desc: 'Rate limit period in seconds. `throttle_authenticated_dependency_proxy_enabled` must be `true`. ' \
          'Default value: `15`.'
      optional :throttle_authenticated_dependency_proxy_requests_per_period,
        desc: 'Maximum requests per period per user. `throttle_authenticated_dependency_proxy_enabled` must be ' \
          '`true`. Default value: `1000`.'
      optional :throttle_authenticated_packages_api_enabled,
        desc: 'If `true`, enables the authenticated package registry API request rate limit. Helps reduce request volume (for example, from crawlers or abusive bots). View [package registry rate limits](https://docs.gitlab.com/rate_limits/api/package-registry/) for more details. Requires `throttle_authenticated_packages_api_period_in_seconds` and `throttle_authenticated_packages_api_requests_per_period`.'
      optional :throttle_authenticated_packages_api_period_in_seconds, desc: 'Rate limit period in seconds. View [package registry rate limits](https://docs.gitlab.com/rate_limits/api/package-registry/) for more details.'
      optional :throttle_authenticated_packages_api_requests_per_period, desc: 'Maximum requests per period per user. View [package registry rate limits](https://docs.gitlab.com/rate_limits/api/package-registry/) for more details.'
      optional :throttle_authenticated_web_enabled,
        desc: 'If `true`, enables the authenticated web request rate limit. Helps reduce request volume (for example, from crawlers or abusive bots). Requires `throttle_authenticated_web_period_in_seconds` and `throttle_authenticated_web_requests_per_period`.'
      optional :throttle_authenticated_web_period_in_seconds, desc: 'Rate limit period in seconds.'
      optional :throttle_authenticated_web_requests_per_period, desc: 'Maximum requests per period per user.'
      optional :throttle_unauthenticated_api_enabled,
        desc: 'If `true`, enables the unauthenticated API request rate limit. Helps reduce request volume (for example, from crawlers or abusive bots). Requires `throttle_unauthenticated_api_period_in_seconds` and `throttle_unauthenticated_api_requests_per_period`.'
      optional :throttle_unauthenticated_api_period_in_seconds, desc: 'Rate limit period in seconds.'
      optional :throttle_unauthenticated_api_requests_per_period, desc: 'Maximum requests per period per IP.'
      optional :throttle_unauthenticated_enabled,
        desc: 'If `true`, enables the unauthenticated web request rate limit. Helps reduce request volume (for example, from crawlers or abusive bots). Requires `throttle_unauthenticated_period_in_seconds` and `throttle_unauthenticated_requests_per_period`. [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/335300) in GitLab 14.3. Use `throttle_unauthenticated_web_enabled` or `throttle_unauthenticated_api_enabled` instead.'
      optional :throttle_unauthenticated_git_http_enabled,
        desc: 'If `true`, enforces the unauthenticated Git HTTP request rate limit. Default value: `false`.'
      optional :throttle_unauthenticated_git_http_period_in_seconds,
        desc: 'Rate limit period in seconds. `throttle_unauthenticated_git_http_enabled` must be `true`. Default ' \
          'value: `3600`.'
      optional :throttle_unauthenticated_git_http_requests_per_period,
        desc: 'Maximum requests per period per IP. `throttle_unauthenticated_git_http_enabled` must be `true`. ' \
          'Default value: `3600`.'
      optional :throttle_unauthenticated_packages_api_enabled,
        desc: 'If `true`, enables the unauthenticated package registry API request rate limit. Helps reduce request volume (for example, from crawlers or abusive bots). View [package registry rate limits](https://docs.gitlab.com/rate_limits/api/package-registry/) for more details. Requires `throttle_unauthenticated_packages_api_period_in_seconds` and `throttle_unauthenticated_packages_api_requests_per_period`.'
      optional :throttle_unauthenticated_packages_api_period_in_seconds, desc: 'Rate limit period in seconds. View [package registry rate limits](https://docs.gitlab.com/rate_limits/api/package-registry/) for more details.'
      optional :throttle_unauthenticated_packages_api_requests_per_period, desc: 'Maximum requests per period per IP. View [package registry rate limits](https://docs.gitlab.com/rate_limits/api/package-registry/) for more details.'
      optional :throttle_unauthenticated_period_in_seconds,
        desc: 'Rate limit period in seconds. [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/335300) in GitLab 14.3. Use `throttle_unauthenticated_web_period_in_seconds` or `throttle_unauthenticated_api_period_in_seconds` instead.'
      optional :throttle_unauthenticated_requests_per_period,
        desc: 'Maximum requests per period per IP. [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/335300) in GitLab 14.3. Use `throttle_unauthenticated_web_requests_per_period` or `throttle_unauthenticated_api_requests_per_period` instead.'
      optional :throttle_unauthenticated_web_enabled,
        desc: 'If `true`, enables the unauthenticated web request rate limit. Helps reduce request volume (for example, from crawlers or abusive bots). Requires `throttle_unauthenticated_web_period_in_seconds` and `throttle_unauthenticated_web_requests_per_period`.'
      optional :throttle_unauthenticated_web_period_in_seconds, desc: 'Rate limit period in seconds.'
      optional :throttle_unauthenticated_web_requests_per_period, desc: 'Maximum requests per period per IP.'
      optional :time_tracking_limit_to_hours, desc: 'If `true`, limits display of time tracking units to hours. Default is `false`.'
      optional :top_level_group_creation_enabled, desc: 'If `true`, users can create top-level groups with the API. Defaults to `true`.'
      optional :unique_ips_limit_enabled,
        desc: 'If `true`, limits sign-ins from multiple IP addresses. Requires `unique_ips_limit_per_user` and `unique_ips_limit_time_window`.'
      optional :unique_ips_limit_per_user, desc: 'Maximum number of IPs per user.'
      optional :unique_ips_limit_time_window, desc: 'How many seconds an IP is counted towards the limit.'
      optional :update_runner_versions_enabled, desc: 'If `true`, fetches GitLab Runner release version data from GitLab.com. For more information, see how to [determine which runners need to be upgraded](https://docs.gitlab.com/ci/runners/runners_scope/#determine-which-runners-need-to-be-upgraded).'
      optional :use_clickhouse_for_analytics,
        desc: 'If `true`, enables ClickHouse as a data source for analytics reports. ClickHouse must be configured for this setting to take effect. Premium and Ultimate only.'
      optional :user_default_external, desc: 'If `true`, newly registered users are external by default.'
      optional :user_default_internal_regex,
        desc: 'Specify an email address regex pattern to identify default internal users.'
      optional :user_defaults_to_private_profile,
        desc: 'If `true`, newly created users have a private profile by default. Defaults to `false`.'
      optional :user_oauth_applications,
        desc: 'If `true`, allows users to register any application to use GitLab as an OAuth provider. This setting does not affect group-level OAuth applications.'
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
      optional :version_check_enabled, desc: 'If `true`, GitLab informs you when an update is available.'
      optional :web_hook_event_resend_limit,
        desc: 'Maximum number of webhook event resend requests per minute, per user, for a given project or group. Default: `5`. Set to `0` to disable limits. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/587887) in GitLab 19.3.'
      optional :web_hook_test_limit,
        desc: 'Maximum number of webhook test requests per minute, per user, for a given project or group. Default: `5`. Set to `0` to disable limits. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/587887) in GitLab 19.3.'
      # rubocop:enable API/ParameterType

      use :optional_params_ee

      # rubocop:disable API/ParameterType, API/ParameterDescription -- `optional_attributes` is a dynamic value, cops do not recognise this pattern
      optional(*Helpers::SettingsHelpers.optional_attributes)
      # rubocop:enable API/ParameterType, API/ParameterDescription
      at_least_one_of(*Helpers::SettingsHelpers.optional_attributes)
    end
    route_setting :authorization, permissions: :update_application_setting, boundary_type: :instance,
      assignable_when: [:admin]
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

      attrs.delete(:code_dropdown_custom_clients) unless Feature.enabled?(:custom_code_dropdown_clients, current_user)

      if ApplicationSettings::UpdateService.new(current_settings, current_user, attrs).execute
        present current_settings, with: Entities::ApplicationSetting
      else
        render_validation_error!(current_settings)
      end
    end
  end
end

API::Settings.prepend_mod_with('API::Settings')
