module API
  class Settings < Grape::API
    before { authenticated_as_admin! }

    helpers do
      def current_settings
        @current_setting ||=
          (ApplicationSetting.current || ApplicationSetting.create_from_defaults)
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
      optional :default_branch_protection, type: Integer, values: [0, 1, 2], desc: 'Determine if developers can push to master'
      optional :default_project_visibility, type: String, values: Gitlab::VisibilityLevel.string_values, desc: 'The default project visibility'
      optional :default_snippet_visibility, type: String, values: Gitlab::VisibilityLevel.string_values, desc: 'The default snippet visibility'
      optional :default_group_visibility, type: String, values: Gitlab::VisibilityLevel.string_values, desc: 'The default group visibility'
      optional :restricted_visibility_levels, type: Array[String], desc: 'Selected levels cannot be used by non-admin users for projects or snippets. If the public level is restricted, user profiles are only visible to logged in users.'
      optional :import_sources, type: Array[String], values: %w[github bitbucket gitlab google_code fogbugz git gitlab_project],
                                desc: 'Enabled sources for code import during project creation. OmniAuth must be configured for GitHub, Bitbucket, and GitLab.com'
      optional :disabled_oauth_sign_in_sources, type: Array[String], desc: 'Disable certain OAuth sign-in sources'
      optional :enabled_git_access_protocol, type: String, values: %w[ssh http nil], desc: 'Allow only the selected protocols to be used for Git access.'
      optional :project_export_enabled, type: Boolean, desc: 'Enable project export'
      optional :gravatar_enabled, type: Boolean, desc: 'Flag indicating if the Gravatar service is enabled'
      optional :default_projects_limit, type: Integer, desc: 'The maximum number of personal projects'
      optional :max_attachment_size, type: Integer, desc: 'Maximum attachment size in MB'
      optional :session_expire_delay, type: Integer, desc: 'Session duration in minutes. GitLab restart is required to apply changes.'
      optional :user_oauth_applications, type: Boolean, desc: 'Allow users to register any application to use GitLab as an OAuth provider'
      optional :user_default_external, type: Boolean, desc: 'Newly registered users will by default be external'
      optional :signup_enabled, type: Boolean, desc: 'Flag indicating if sign up is enabled'
      optional :send_user_confirmation_email, type: Boolean, desc: 'Send confirmation email on sign-up'
      optional :domain_whitelist, type: String, desc: 'ONLY users with e-mail addresses that match these domain(s) will be able to sign-up. Wildcards allowed. Use separate lines for multiple entries. Ex: domain.com, *.domain.com'
      optional :domain_blacklist_enabled, type: Boolean, desc: 'Enable domain blacklist for sign ups'
      given domain_blacklist_enabled: ->(val) { val } do
        requires :domain_blacklist, type: String, desc: 'Users with e-mail addresses that match these domain(s) will NOT be able to sign-up. Wildcards allowed. Use separate lines for multiple entries. Ex: domain.com, *.domain.com'
      end
      optional :after_sign_up_text, type: String, desc: 'Text shown after sign up'
      optional :password_authentication_enabled_for_web, type: Boolean, desc: 'Flag indicating if password authentication is enabled for the web interface'
      optional :password_authentication_enabled, type: Boolean, desc: 'Flag indicating if password authentication is enabled for the web interface' # support legacy names, can be removed in v5
      optional :signin_enabled, type: Boolean, desc: 'Flag indicating if password authentication is enabled for the web interface' # support legacy names, can be removed in v5
      mutually_exclusive :password_authentication_enabled_for_web, :password_authentication_enabled, :signin_enabled
      optional :password_authentication_enabled_for_git, type: Boolean, desc: 'Flag indicating if password authentication is enabled for Git over HTTP(S)'
      optional :require_two_factor_authentication, type: Boolean, desc: 'Require all users to setup Two-factor authentication'
      given require_two_factor_authentication: ->(val) { val } do
        requires :two_factor_grace_period, type: Integer, desc: 'Amount of time (in hours) that users are allowed to skip forced configuration of two-factor authentication'
      end
      optional :home_page_url, type: String, desc: 'We will redirect non-logged in users to this page'
      optional :after_sign_out_path, type: String, desc: 'We will redirect users to this page after they sign out'
      optional :sign_in_text, type: String, desc: 'The sign in text of the GitLab application'
      optional :help_page_hide_commercial_content, type: Boolean, desc: 'Hide marketing-related entries from help'
      optional :help_page_text, type: String, desc: 'Custom text displayed on the help page'
      optional :help_page_support_url, type: String, desc: 'Alternate support URL for help page'
      optional :shared_runners_enabled, type: Boolean, desc: 'Enable shared runners for new projects'
      given shared_runners_enabled: ->(val) { val } do
        requires :shared_runners_text, type: String, desc: 'Shared runners text '
      end
      optional :max_artifacts_size, type: Integer, desc: "Set the maximum file size for each job's artifacts"
      optional :default_artifacts_expire_in, type: String, desc: "Set the default expiration time for each job's artifacts"
      optional :max_pages_size, type: Integer, desc: 'Maximum size of pages in MB'
      optional :container_registry_token_expire_delay, type: Integer, desc: 'Authorization token duration (minutes)'
      optional :prometheus_metrics_enabled, type: Boolean, desc: 'Enable Prometheus metrics'
      optional :metrics_enabled, type: Boolean, desc: 'Enable the InfluxDB metrics'
      given metrics_enabled: ->(val) { val } do
        requires :metrics_host, type: String, desc: 'The InfluxDB host'
        requires :metrics_port, type: Integer, desc: 'The UDP port to use for connecting to InfluxDB'
        requires :metrics_pool_size, type: Integer, desc: 'The amount of InfluxDB connections to open'
        requires :metrics_timeout, type: Integer, desc: 'The amount of seconds after which an InfluxDB connection will time out'
        requires :metrics_method_call_threshold, type: Integer, desc: 'A method call is only tracked when it takes longer to complete than the given amount of milliseconds.'
        requires :metrics_sample_interval, type: Integer, desc: 'The sampling interval in seconds'
        requires :metrics_packet_size, type: Integer, desc: 'The amount of points to store in a single UDP packet'
      end
      optional :sidekiq_throttling_enabled, type: Boolean, desc: 'Enable Sidekiq Job Throttling'
      given sidekiq_throttling_enabled: ->(val) { val } do
        requires :sidekiq_throttling_queus, type: Array[String], desc: 'Choose which queues you wish to throttle'
        requires :sidekiq_throttling_factor, type: Float, desc: 'The factor by which the queues should be throttled. A value between 0.0 and 1.0, exclusive.'
      end
      optional :recaptcha_enabled, type: Boolean, desc: 'Helps prevent bots from creating accounts'
      given recaptcha_enabled: ->(val) { val } do
        requires :recaptcha_site_key, type: String, desc: 'Generate site key at http://www.google.com/recaptcha'
        requires :recaptcha_private_key, type: String, desc: 'Generate private key at http://www.google.com/recaptcha'
      end
      optional :akismet_enabled, type: Boolean, desc: 'Helps prevent bots from creating issues'
      given akismet_enabled: ->(val) { val } do
        requires :akismet_api_key, type: String, desc: 'Generate API key at http://www.akismet.com'
      end
      optional :admin_notification_email, type: String, desc: 'Abuse reports will be sent to this address if it is set. Abuse reports are always available in the admin area.'
      optional :sentry_enabled, type: Boolean, desc: 'Sentry is an error reporting and logging tool which is currently not shipped with GitLab, get it here: https://getsentry.com'
      given sentry_enabled: ->(val) { val } do
        requires :sentry_dsn, type: String, desc: 'Sentry Data Source Name'
      end
      optional :clientside_sentry_enabled, type: Boolean, desc: 'Sentry can also be used for reporting and logging clientside exceptions. https://sentry.io/for/javascript/'
      given clientside_sentry_enabled: ->(val) { val } do
        requires :clientside_sentry_dsn, type: String, desc: 'Clientside Sentry Data Source Name'
      end
      optional :repository_storages, type: Array[String], desc: 'Storage paths for new projects'
      optional :repository_checks_enabled, type: Boolean, desc: "GitLab will periodically run 'git fsck' in all project and wiki repositories to look for silent disk corruption issues."
      optional :koding_enabled, type: Boolean, desc: 'Enable Koding'
      given koding_enabled: ->(val) { val } do
        requires :koding_url, type: String, desc: 'The Koding team URL'
      end
      optional :plantuml_enabled, type: Boolean, desc: 'Enable PlantUML'
      given plantuml_enabled: ->(val) { val } do
        requires :plantuml_url, type: String, desc: 'The PlantUML server URL'
      end
      optional :version_check_enabled, type: Boolean, desc: 'Let GitLab inform you when an update is available.'
      optional :email_author_in_body, type: Boolean, desc: 'Some email servers do not support overriding the email sender name. Enable this option to include the name of the author of the issue, merge request or comment in the email body instead.'
      optional :html_emails_enabled, type: Boolean, desc: 'By default GitLab sends emails in HTML and plain text formats so mail clients can choose what format to use. Disable this option if you only want to send emails in plain text format.'
      optional :housekeeping_enabled, type: Boolean, desc: 'Enable automatic repository housekeeping (git repack, git gc)'
      given housekeeping_enabled: ->(val) { val } do
        requires :housekeeping_bitmaps_enabled, type: Boolean, desc: "Creating pack file bitmaps makes housekeeping take a little longer but bitmaps should accelerate 'git clone' performance."
        requires :housekeeping_incremental_repack_period, type: Integer, desc: "Number of Git pushes after which an incremental 'git repack' is run."
        requires :housekeeping_full_repack_period, type: Integer, desc: "Number of Git pushes after which a full 'git repack' is run."
        requires :housekeeping_gc_period, type: Integer, desc: "Number of Git pushes after which 'git gc' is run."
      end
      optional :terminal_max_session_time, type: Integer, desc: 'Maximum time for web terminal websocket connection (in seconds). Set to 0 for unlimited time.'
      optional :polling_interval_multiplier, type: BigDecimal, desc: 'Interval multiplier used by endpoints that perform polling. Set to 0 to disable polling.'
      optional :gitaly_timeout_default, type: Integer, desc: 'Default Gitaly timeout, in seconds. Set to 0 to disable timeouts.'
      optional :gitaly_timeout_medium, type: Integer, desc: 'Medium Gitaly timeout, in seconds. Set to 0 to disable timeouts.'
      optional :gitaly_timeout_fast, type: Integer, desc: 'Gitaly fast operation timeout, in seconds. Set to 0 to disable timeouts.'

      ApplicationSetting::SUPPORTED_KEY_TYPES.each do |type|
        optional :"#{type}_key_restriction",
                 type: Integer,
                 values: KeyRestrictionValidator.supported_key_restrictions(type),
                 desc: "Restrictions on the complexity of uploaded #{type.upcase} keys. A value of #{ApplicationSetting::FORBIDDEN_KEY_VALUE} disables all #{type.upcase} keys."
      end

      optional(*::ApplicationSettingsHelper.visible_attributes)
      at_least_one_of(*::ApplicationSettingsHelper.visible_attributes)
    end
    put "application/settings" do
      attrs = declared_params(include_missing: false)

      # support legacy names, can be removed in v5
      if attrs.has_key?(:signin_enabled)
        attrs[:password_authentication_enabled_for_web] = attrs.delete(:signin_enabled)
      elsif attrs.has_key?(:password_authentication_enabled)
        attrs[:password_authentication_enabled_for_web] = attrs.delete(:password_authentication_enabled)
      end

      if ApplicationSettings::UpdateService.new(current_settings, current_user, attrs).execute
        present current_settings, with: Entities::ApplicationSetting
      else
        render_validation_error!(current_settings)
      end
    end
  end
end
