# frozen_string_literal: true

module API
  class Settings < Grape::API
    before { authenticated_as_admin! }

    helpers Helpers::SettingsHelpers

    helpers do
      def current_settings
        @current_setting ||=
          (ApplicationSetting.current_without_cache || ApplicationSetting.create_from_defaults)
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
      optional :admin_notification_email, type: String, desc: 'Abuse reports will be sent to this address if it is set. Abuse reports are always available in the admin area.'
      optional :after_sign_up_text, type: String, desc: 'Text shown after sign up'
      optional :after_sign_out_path, type: String, desc: 'We will redirect users to this page after they sign out'
      optional :akismet_enabled, type: Boolean, desc: 'Helps prevent bots from creating issues'
      given akismet_enabled: ->(val) { val } do
        requires :akismet_api_key, type: String, desc: 'Generate API key at http://www.akismet.com'
      end
      optional :asset_proxy_enabled, type: Boolean, desc: 'Enable proxying of assets'
      optional :asset_proxy_url, type: String, desc: 'URL of the asset proxy server'
      optional :asset_proxy_secret_key, type: String, desc: 'Shared secret with the asset proxy server'
      optional :asset_proxy_whitelist, type: Array[String], coerce_with: Validations::Types::CommaSeparatedToArray.coerce, desc: 'Assets that match these domain(s) will NOT be proxied. Wildcards allowed. Your GitLab installation URL is automatically whitelisted.'
      optional :container_registry_token_expire_delay, type: Integer, desc: 'Authorization token duration (minutes)'
      optional :default_artifacts_expire_in, type: String, desc: "Set the default expiration time for each job's artifacts"
      optional :default_ci_config_path, type: String, desc: 'The instance default CI configuration path for new projects'
      optional :default_project_creation, type: Integer, values: ::Gitlab::Access.project_creation_values, desc: 'Determine if developers can create projects in the group'
      optional :default_branch_protection, type: Integer, values: ::Gitlab::Access.protection_values, desc: 'Determine if developers can push to master'
      optional :default_group_visibility, type: String, values: Gitlab::VisibilityLevel.string_values, desc: 'The default group visibility'
      optional :default_project_visibility, type: String, values: Gitlab::VisibilityLevel.string_values, desc: 'The default project visibility'
      optional :default_projects_limit, type: Integer, desc: 'The maximum number of personal projects'
      optional :default_snippet_visibility, type: String, values: Gitlab::VisibilityLevel.string_values, desc: 'The default snippet visibility'
      optional :disabled_oauth_sign_in_sources, type: Array[String], desc: 'Disable certain OAuth sign-in sources'
      optional :domain_blacklist_enabled, type: Boolean, desc: 'Enable domain blacklist for sign ups'
      optional :domain_blacklist, type: Array[String], coerce_with: Validations::Types::CommaSeparatedToArray.coerce, desc: 'Users with e-mail addresses that match these domain(s) will NOT be able to sign-up. Wildcards allowed. Use separate lines for multiple entries. Ex: domain.com, *.domain.com'
      optional :domain_whitelist, type: Array[String], coerce_with: Validations::Types::CommaSeparatedToArray.coerce, desc: 'ONLY users with e-mail addresses that match these domain(s) will be able to sign-up. Wildcards allowed. Use separate lines for multiple entries. Ex: domain.com, *.domain.com'
      optional :eks_integration_enabled, type: Boolean, desc: 'Enable integration with Amazon EKS'
      given eks_integration_enabled: -> (val) { val } do
        requires :eks_account_id, type: String, desc: 'Amazon account ID for EKS integration'
        requires :eks_access_key_id, type: String, desc: 'Access key ID for the EKS integration IAM user'
        requires :eks_secret_access_key, type: String, desc: 'Secret access key for the EKS integration IAM user'
      end
      optional :email_author_in_body, type: Boolean, desc: 'Some email servers do not support overriding the email sender name. Enable this option to include the name of the author of the issue, merge request or comment in the email body instead.'
      optional :enabled_git_access_protocol, type: String, values: %w[ssh http nil], desc: 'Allow only the selected protocols to be used for Git access.'
      optional :gitaly_timeout_default, type: Integer, desc: 'Default Gitaly timeout, in seconds. Set to 0 to disable timeouts.'
      optional :gitaly_timeout_fast, type: Integer, desc: 'Gitaly fast operation timeout, in seconds. Set to 0 to disable timeouts.'
      optional :gitaly_timeout_medium, type: Integer, desc: 'Medium Gitaly timeout, in seconds. Set to 0 to disable timeouts.'
      optional :grafana_enabled, type: Boolean, desc: 'Enable Grafana'
      optional :grafana_url, type: String, desc: 'Grafana URL'
      optional :gravatar_enabled, type: Boolean, desc: 'Flag indicating if the Gravatar service is enabled'
      optional :help_page_hide_commercial_content, type: Boolean, desc: 'Hide marketing-related entries from help'
      optional :help_page_support_url, type: String, desc: 'Alternate support URL for help page and help dropdown'
      optional :help_page_text, type: String, desc: 'Custom text displayed on the help page'
      optional :home_page_url, type: String, desc: 'We will redirect non-logged in users to this page'
      optional :housekeeping_enabled, type: Boolean, desc: 'Enable automatic repository housekeeping (git repack, git gc)'
      given housekeeping_enabled: ->(val) { val } do
        requires :housekeeping_bitmaps_enabled, type: Boolean, desc: "Creating pack file bitmaps makes housekeeping take a little longer but bitmaps should accelerate 'git clone' performance."
        requires :housekeeping_full_repack_period, type: Integer, desc: "Number of Git pushes after which a full 'git repack' is run."
        requires :housekeeping_gc_period, type: Integer, desc: "Number of Git pushes after which 'git gc' is run."
        requires :housekeeping_incremental_repack_period, type: Integer, desc: "Number of Git pushes after which an incremental 'git repack' is run."
      end
      optional :html_emails_enabled, type: Boolean, desc: 'By default GitLab sends emails in HTML and plain text formats so mail clients can choose what format to use. Disable this option if you only want to send emails in plain text format.'
      optional :import_sources, type: Array[String], values: %w[github bitbucket bitbucket_server gitlab google_code fogbugz git gitlab_project gitea manifest phabricator],
                                desc: 'Enabled sources for code import during project creation. OmniAuth must be configured for GitHub, Bitbucket, and GitLab.com'
      optional :max_artifacts_size, type: Integer, desc: "Set the maximum file size for each job's artifacts"
      optional :max_attachment_size, type: Integer, desc: 'Maximum attachment size in MB'
      optional :max_pages_size, type: Integer, desc: 'Maximum size of pages in MB'
      optional :metrics_enabled, type: Boolean, desc: 'Enable the InfluxDB metrics'
      given metrics_enabled: ->(val) { val } do
        requires :metrics_host, type: String, desc: 'The InfluxDB host'
        requires :metrics_method_call_threshold, type: Integer, desc: 'A method call is only tracked when it takes longer to complete than the given amount of milliseconds.'
        requires :metrics_packet_size, type: Integer, desc: 'The amount of points to store in a single UDP packet'
        requires :metrics_pool_size, type: Integer, desc: 'The amount of InfluxDB connections to open'
        requires :metrics_port, type: Integer, desc: 'The UDP port to use for connecting to InfluxDB'
        requires :metrics_sample_interval, type: Integer, desc: 'The sampling interval in seconds'
        requires :metrics_timeout, type: Integer, desc: 'The amount of seconds after which an InfluxDB connection will time out'
      end
      optional :password_authentication_enabled, type: Boolean, desc: 'Flag indicating if password authentication is enabled for the web interface' # support legacy names, can be removed in v5
      optional :password_authentication_enabled_for_web, type: Boolean, desc: 'Flag indicating if password authentication is enabled for the web interface'
      mutually_exclusive :password_authentication_enabled_for_web, :password_authentication_enabled, :signin_enabled
      optional :password_authentication_enabled_for_git, type: Boolean, desc: 'Flag indicating if password authentication is enabled for Git over HTTP(S)'
      optional :performance_bar_allowed_group_id, type: String, desc: 'Deprecated: Use :performance_bar_allowed_group_path instead. Path of the group that is allowed to toggle the performance bar.' # support legacy names, can be removed in v6
      optional :performance_bar_allowed_group_path, type: String, desc: 'Path of the group that is allowed to toggle the performance bar.'
      optional :performance_bar_enabled, type: String, desc: 'Deprecated: Pass `performance_bar_allowed_group_path: nil` instead. Allow enabling the performance.' # support legacy names, can be removed in v6
      optional :plantuml_enabled, type: Boolean, desc: 'Enable PlantUML'
      given plantuml_enabled: ->(val) { val } do
        requires :plantuml_url, type: String, desc: 'The PlantUML server URL'
      end
      optional :polling_interval_multiplier, type: BigDecimal, desc: 'Interval multiplier used by endpoints that perform polling. Set to 0 to disable polling.'
      optional :project_export_enabled, type: Boolean, desc: 'Enable project export'
      optional :prometheus_metrics_enabled, type: Boolean, desc: 'Enable Prometheus metrics'
      optional :push_event_hooks_limit, type: Integer, desc: "Number of changes (branches or tags) in a single push to determine whether webhooks and services will be fired or not. Webhooks and services won't be submitted if it surpasses that value."
      optional :push_event_activities_limit, type: Integer, desc: 'Number of changes (branches or tags) in a single push to determine whether individual push events or bulk push event will be created. Bulk push event will be created if it surpasses that value.'
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
      optional :repository_storages, type: Array[String], desc: 'Storage paths for new projects'
      optional :require_two_factor_authentication, type: Boolean, desc: 'Require all users to set up Two-factor authentication'
      given require_two_factor_authentication: ->(val) { val } do
        requires :two_factor_grace_period, type: Integer, desc: 'Amount of time (in hours) that users are allowed to skip forced configuration of two-factor authentication'
      end
      optional :restricted_visibility_levels, type: Array[String], desc: 'Selected levels cannot be used by non-admin users for groups, projects or snippets. If the public level is restricted, user profiles are only visible to logged in users.'
      optional :send_user_confirmation_email, type: Boolean, desc: 'Send confirmation email on sign-up'
      optional :session_expire_delay, type: Integer, desc: 'Session duration in minutes. GitLab restart is required to apply changes.'
      optional :shared_runners_enabled, type: Boolean, desc: 'Enable shared runners for new projects'
      given shared_runners_enabled: ->(val) { val } do
        requires :shared_runners_text, type: String, desc: 'Shared runners text '
      end
      optional :sign_in_text, type: String, desc: 'The sign in text of the GitLab application'
      optional :signin_enabled, type: Boolean, desc: 'Flag indicating if password authentication is enabled for the web interface' # support legacy names, can be removed in v5
      optional :signup_enabled, type: Boolean, desc: 'Flag indicating if sign up is enabled'
      optional :sourcegraph_enabled, type: Boolean, desc: 'Enable Sourcegraph'
      optional :sourcegraph_public_only, type: Boolean, desc: 'Only allow public projects to communicate with Sourcegraph'
      given sourcegraph_enabled: ->(val) { val } do
        requires :sourcegraph_url, type: String, desc: 'The configured Sourcegraph instance URL'
      end
      optional :terminal_max_session_time, type: Integer, desc: 'Maximum time for web terminal websocket connection (in seconds). Set to 0 for unlimited time.'
      optional :updating_name_disabled_for_users, type: Boolean, desc: 'Flag indicating if users are permitted to update their profile name'
      optional :usage_ping_enabled, type: Boolean, desc: 'Every week GitLab will report license usage back to GitLab, Inc.'
      optional :instance_statistics_visibility_private, type: Boolean, desc: 'When set to `true` Instance statistics will only be available to admins'
      optional :local_markdown_version, type: Integer, desc: 'Local markdown version, increase this value when any cached markdown should be invalidated'
      optional :allow_local_requests_from_hooks_and_services, type: Boolean, desc: 'Deprecated: Use :allow_local_requests_from_web_hooks_and_services instead. Allow requests to the local network from hooks and services.' # support legacy names, can be removed in v5
      optional :snowplow_enabled, type: Grape::API::Boolean, desc: 'Enable Snowplow tracking'
      optional :snowplow_iglu_registry_url, type: String, desc: 'The Snowplow base Iglu Schema Registry URL to use for custom context and self describing events'
      given snowplow_enabled: ->(val) { val } do
        requires :snowplow_collector_hostname, type: String, desc: 'The Snowplow collector hostname'
        optional :snowplow_cookie_domain, type: String, desc: 'The Snowplow cookie domain'
        optional :snowplow_app_id, type: String, desc: 'The Snowplow site name / application id'
      end

      ApplicationSetting::SUPPORTED_KEY_TYPES.each do |type|
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

      attrs = filter_attributes_using_license(attrs)

      if ApplicationSettings::UpdateService.new(current_settings, current_user, attrs).execute
        present current_settings, with: Entities::ApplicationSetting
      else
        render_validation_error!(current_settings)
      end
    end
  end
end

API::Settings.prepend_if_ee('EE::API::Settings')
