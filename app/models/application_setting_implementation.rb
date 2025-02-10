# frozen_string_literal: true

module ApplicationSettingImplementation
  extend ActiveSupport::Concern
  include Gitlab::Utils::StrongMemoize

  STRING_LIST_SEPARATOR = %r{\s*[,;]\s*     # comma or semicolon, optionally surrounded by whitespace
                            |               # or
                            \s              # any whitespace character
                            |               # or
                            [\r\n]          # any number of newline characters
                          }x

  # Setting a key restriction to `-1` means that all keys of this type are
  # forbidden.
  FORBIDDEN_KEY_VALUE = KeyRestrictionValidator::FORBIDDEN
  VALID_RUNNER_REGISTRAR_TYPES = %w[project group].freeze

  DEFAULT_PROTECTED_PATHS = [
    '/users/password',
    '/users/sign_in',
    '/api/v3/session.json',
    '/api/v3/session',
    '/api/v4/session.json',
    '/api/v4/session',
    '/users',
    '/users/confirmation',
    '/unsubscribes/',
    '/import/github/personal_access_token',
    '/admin/session'
  ].freeze

  DEFAULT_MINIMUM_PASSWORD_LENGTH = 8

  class_methods do
    def defaults # rubocop:disable Metrics/AbcSize
      {
        admin_mode: false,
        after_sign_up_text: nil,
        akismet_enabled: false,
        akismet_api_key: nil,
        allow_local_requests_from_system_hooks: true,
        allow_local_requests_from_web_hooks_and_services: false,
        allow_possible_spam: false,
        asset_proxy_enabled: false,
        authorized_keys_enabled: true, # TODO default to false if the instance is configured to use AuthorizedKeysCommand
        ci_max_total_yaml_size_bytes: 314572800, # max_yaml_size_bytes * ci_max_includes = 2.megabyte * 150
        commit_email_hostname: default_commit_email_hostname,
        container_expiration_policies_enable_historic_entries: false,
        container_registry_features: [],
        container_registry_token_expire_delay: 5,
        container_registry_vendor: '',
        container_registry_version: '',
        container_registry_db_enabled: false,
        custom_http_clone_url_root: nil,
        decompress_archive_file_timeout: 210,
        default_artifacts_expire_in: '30 days',
        default_branch_name: nil,
        default_branch_protection: Settings.gitlab['default_branch_protection'],
        default_branch_protection_defaults: Settings.gitlab['default_branch_protection_defaults'],
        default_ci_config_path: nil,
        default_group_visibility: Settings.gitlab.default_projects_features['visibility_level'],
        default_project_creation: Settings.gitlab['default_project_creation'],
        default_project_visibility: Settings.gitlab.default_projects_features['visibility_level'],
        default_projects_limit: Settings.gitlab['default_projects_limit'],
        default_snippet_visibility: Settings.gitlab.default_projects_features['visibility_level'],
        default_syntax_highlighting_theme: 1,
        deny_all_requests_except_allowed: false,
        diff_max_patch_bytes: Gitlab::Git::Diff::DEFAULT_MAX_PATCH_BYTES,
        diff_max_files: Commit::DEFAULT_MAX_DIFF_FILES_SETTING,
        diff_max_lines: Commit::DEFAULT_MAX_DIFF_LINES_SETTING,
        disable_admin_oauth_scopes: false,
        disable_feed_token: false,
        disabled_direct_code_suggestions: false,
        disabled_oauth_sign_in_sources: [],
        disable_password_authentication_for_users_with_sso_identities: false,
        root_moved_permanently_redirection: false,
        dns_rebinding_protection_enabled: Settings.gitlab['dns_rebinding_protection_enabled'],
        domain_allowlist: Settings.gitlab['domain_allowlist'],
        dsa_key_restriction: default_min_key_size(:dsa),
        ecdsa_key_restriction: default_min_key_size(:ecdsa),
        ecdsa_sk_key_restriction: default_min_key_size(:ecdsa_sk),
        ed25519_key_restriction: default_min_key_size(:ed25519),
        ed25519_sk_key_restriction: default_min_key_size(:ed25519_sk),
        require_admin_two_factor_authentication: false,
        eks_access_key_id: nil,
        eks_account_id: nil,
        eks_integration_enabled: false,
        eks_secret_access_key: nil,
        email_confirmation_setting: 'off',
        email_restrictions_enabled: false,
        email_restrictions: nil,
        external_pipeline_validation_service_timeout: nil,
        external_pipeline_validation_service_token: nil,
        external_pipeline_validation_service_url: nil,
        failed_login_attempts_unlock_period_in_minutes: nil,
        fetch_observability_alerts_from_cloud: true,
        first_day_of_week: 0,
        floc_enabled: false,
        gitaly_timeout_default: 55,
        gitaly_timeout_fast: 10,
        gitaly_timeout_medium: 30,
        gitpod_enabled: false,
        gitpod_url: 'https://gitpod.io/',
        gravatar_enabled: Settings.gravatar['enabled'],
        group_download_export_limit: 1,
        group_export_limit: 6,
        group_import_limit: 6,
        help_page_hide_commercial_content: false,
        help_page_text: nil,
        help_page_documentation_base_url: 'https://docs.gitlab.com',
        hide_third_party_offers: false,
        housekeeping_enabled: true,
        housekeeping_full_repack_period: 50,
        housekeeping_gc_period: 200,
        housekeeping_incremental_repack_period: 10,
        import_sources: Settings.gitlab['import_sources'],
        include_optional_metrics_in_service_ping: Settings.gitlab['usage_ping_enabled'],
        instance_level_ai_beta_features_enabled: false,
        invisible_captcha_enabled: false,
        issues_create_limit: 300,
        jira_connect_application_key: nil,
        jira_connect_public_key_storage_enabled: false,
        jira_connect_proxy_url: nil,
        local_markdown_version: 0,
        login_recaptcha_protection_enabled: false,
        mailgun_signing_key: nil,
        mailgun_events_enabled: false,
        math_rendering_limits_enabled: true,
        max_artifacts_content_include_size: 5.megabytes,
        max_artifacts_size: Settings.artifacts['max_size'],
        max_attachment_size: Settings.gitlab['max_attachment_size'],
        max_decompressed_archive_size: 25600,
        max_export_size: 0,
        max_import_size: 0,
        max_import_remote_file_size: 10240,
        max_login_attempts: nil,
        max_terraform_state_size_bytes: 0,
        max_yaml_size_bytes: 2.megabyte,
        max_yaml_depth: 100,
        minimum_password_length: DEFAULT_MINIMUM_PASSWORD_LENGTH,
        mirror_available: true,
        notes_create_limit: 300,
        notes_create_limit_allowlist: [],
        members_delete_limit: 60,
        notify_on_unknown_sign_in: true,
        outbound_local_requests_whitelist: [],
        password_authentication_enabled_for_git: true,
        password_authentication_enabled_for_web: Settings.gitlab['signin_enabled'],
        performance_bar_allowed_group_id: nil,
        personal_access_token_prefix: 'glpat-',
        plantuml_enabled: false,
        plantuml_url: nil,
        diagramsnet_enabled: true,
        diagramsnet_url: 'https://embed.diagrams.net',
        polling_interval_multiplier: 1,
        productivity_analytics_start_date: Time.current,
        project_download_export_limit: 1,
        project_export_enabled: true,
        project_export_limit: 6,
        project_import_limit: 6,
        protected_ci_variables: true,
        protected_paths: DEFAULT_PROTECTED_PATHS,
        push_event_activities_limit: 3,
        push_event_hooks_limit: 3,
        raw_blob_request_limit: 300,
        recaptcha_enabled: false,
        receptive_cluster_agents_enabled: false,
        repository_checks_enabled: true,
        repository_storages_weighted: { 'default' => 100 },
        require_admin_approval_after_user_signup: true,
        require_two_factor_authentication: false,
        resource_usage_limits: {},
        resource_access_token_notify_inherited: false,
        lock_resource_access_token_notify_inherited: false,
        restricted_visibility_levels: Settings.gitlab['restricted_visibility_levels'],
        rsa_key_restriction: default_min_key_size(:rsa),
        session_expire_delay: Settings.gitlab['session_expire_delay'],
        shared_runners_enabled: Settings.gitlab_ci['shared_runners_enabled'],
        shared_runners_text: nil,
        sidekiq_job_limiter_mode: Gitlab::SidekiqMiddleware::SizeLimiter::Validator::COMPRESS_MODE,
        sidekiq_job_limiter_compression_threshold_bytes: Gitlab::SidekiqMiddleware::SizeLimiter::Validator::DEFAULT_COMPRESSION_THRESHOLD_BYTES,
        sidekiq_job_limiter_limit_bytes: Gitlab::SidekiqMiddleware::SizeLimiter::Validator::DEFAULT_SIZE_LIMIT,
        signup_enabled: Settings.gitlab['signup_enabled'],
        snippet_size_limit: 50.megabytes,
        snowplow_app_id: nil,
        snowplow_collector_hostname: nil,
        snowplow_cookie_domain: nil,
        snowplow_database_collector_hostname: nil,
        snowplow_enabled: false,
        sourcegraph_enabled: false,
        sourcegraph_public_only: true,
        sourcegraph_url: nil,
        spam_check_endpoint_enabled: false,
        spam_check_endpoint_url: nil,
        spam_check_api_key: nil,
        suggest_pipeline_enabled: true,
        terminal_max_session_time: 0,
        throttle_authenticated_api_enabled: false,
        throttle_authenticated_api_period_in_seconds: 3600,
        throttle_authenticated_api_requests_per_period: 7200,
        throttle_authenticated_git_lfs_enabled: false,
        throttle_authenticated_git_lfs_period_in_seconds: 60,
        throttle_authenticated_git_lfs_requests_per_period: 1000,
        throttle_authenticated_web_enabled: false,
        throttle_authenticated_web_period_in_seconds: 3600,
        throttle_authenticated_web_requests_per_period: 7200,
        throttle_authenticated_packages_api_enabled: false,
        throttle_authenticated_packages_api_period_in_seconds: 15,
        throttle_authenticated_packages_api_requests_per_period: 1000,
        throttle_authenticated_files_api_enabled: false,
        throttle_authenticated_files_api_period_in_seconds: 15,
        throttle_authenticated_files_api_requests_per_period: 500,
        throttle_authenticated_deprecated_api_enabled: false,
        throttle_authenticated_deprecated_api_period_in_seconds: 3600,
        throttle_authenticated_deprecated_api_requests_per_period: 3600,
        throttle_incident_management_notification_enabled: false,
        throttle_incident_management_notification_per_period: 3600,
        throttle_incident_management_notification_period_in_seconds: 3600,
        throttle_protected_paths_enabled: false,
        throttle_protected_paths_in_seconds: 10,
        throttle_protected_paths_per_period: 60,
        throttle_unauthenticated_api_enabled: false,
        throttle_unauthenticated_api_period_in_seconds: 3600,
        throttle_unauthenticated_api_requests_per_period: 3600,
        throttle_unauthenticated_enabled: false,
        throttle_unauthenticated_period_in_seconds: 3600,
        throttle_unauthenticated_requests_per_period: 3600,
        throttle_unauthenticated_packages_api_enabled: false,
        throttle_unauthenticated_packages_api_period_in_seconds: 15,
        throttle_unauthenticated_packages_api_requests_per_period: 800,
        throttle_unauthenticated_files_api_enabled: false,
        throttle_unauthenticated_files_api_period_in_seconds: 15,
        throttle_unauthenticated_files_api_requests_per_period: 125,
        throttle_unauthenticated_deprecated_api_enabled: false,
        throttle_unauthenticated_deprecated_api_period_in_seconds: 3600,
        throttle_unauthenticated_deprecated_api_requests_per_period: 1800,
        time_tracking_limit_to_hours: false,
        two_factor_grace_period: 48,
        unique_ips_limit_enabled: false,
        unique_ips_limit_per_user: 10,
        unique_ips_limit_time_window: 3600,
        usage_ping_enabled: Settings.gitlab['usage_ping_enabled'],
        usage_ping_features_enabled: false,
        usage_stats_set_by_user_id: nil,
        user_default_external: false,
        user_default_internal_regex: nil,
        user_show_add_ssh_key_message: true,
        valid_runner_registrars: VALID_RUNNER_REGISTRAR_TYPES,
        wiki_page_max_content_bytes: 50.megabytes,
        wiki_asciidoc_allow_uri_includes: false,
        package_registry_cleanup_policies_worker_capacity: 2,
        container_registry_delete_tags_service_timeout: 250,
        container_registry_expiration_policies_worker_capacity: 4,
        container_registry_cleanup_tags_service_max_list_size: 200,
        container_registry_expiration_policies_caching: true,
        kroki_enabled: false,
        kroki_url: nil,
        kroki_formats: { blockdiag: false, bpmn: false, excalidraw: false },
        rate_limiting_response_text: nil,
        whats_new_variant: 0,
        user_deactivation_emails_enabled: true,
        search_rate_limit: 30,
        search_rate_limit_unauthenticated: 10,
        search_rate_limit_allowlist: [],
        users_get_by_id_limit: 300,
        users_get_by_id_limit_allowlist: [],
        can_create_group: true,
        can_create_organization: true,
        bulk_import_enabled: false,
        bulk_import_max_download_file_size: 5120,
        silent_admin_exports_enabled: false,
        allow_contribution_mapping_to_admins: false,
        allow_runner_registration_token: true,
        user_defaults_to_private_profile: false,
        projects_api_rate_limit_unauthenticated: 400,
        gitlab_dedicated_instance: false,
        gitlab_environment_toolkit_instance: false,
        ci_max_includes: 150,
        allow_account_deletion: true,
        gitlab_shell_operation_limit: 600,
        project_jobs_api_rate_limit: 600,
        security_txt_content: nil,
        allow_project_creation_for_guest_and_below: true,
        enable_member_promotion_management: false,
        security_approval_policies_limit: 5,
        downstream_pipeline_trigger_limit_per_project_user_sha: 0,
        asciidoc_max_includes: 32,
        use_clickhouse_for_analytics: false,
        group_api_limit: 400,
        group_invited_groups_api_limit: 60,
        group_projects_api_limit: 600,
        group_shared_groups_api_limit: 60,
        groups_api_limit: 200,
        create_organization_api_limit: 10,
        project_api_limit: 400,
        project_invited_groups_api_limit: 60,
        projects_api_limit: 2000,
        user_contributed_projects_api_limit: 100,
        user_projects_api_limit: 300,
        user_starred_projects_api_limit: 100,
        nuget_skip_metadata_url_validation: false,
        ai_action_api_rate_limit: 160,
        code_suggestions_api_rate_limit: 60,
        require_personal_access_token_expiry: true,
        pages_extra_deployments_default_expiry_seconds: 86400,
        scan_execution_policies_action_limit: 10,
        seat_control: 0,
        show_migrate_from_jenkins_banner: true,
        ropc_without_client_credentials: true
      }.tap do |hsh|
        hsh.merge!(non_production_defaults) unless Rails.env.production?
      end
    end

    def non_production_defaults
      {}
    end

    def default_commit_email_hostname
      "users.noreply.#{Gitlab.config.gitlab.host}"
    end

    # Return the default allowed minimum key size for a type.
    # By default this is 0 (unrestricted), but in FIPS mode
    # this will return the smallest allowed key size. If no
    # size is available, this type is denied.
    #
    # @return [Integer]
    def default_min_key_size(name)
      if Gitlab::FIPS.enabled?
        Gitlab::SSHPublicKey.supported_sizes(name).select(&:positive?).min || -1
      else
        0
      end
    end

    def create_from_defaults
      build_from_defaults.tap(&:save)
    end

    def human_attribute_name(attr, _options = {})
      if attr == :default_artifacts_expire_in
        'Default artifacts expiration'
      else
        super
      end
    end
  end

  def home_page_url_column_exists?
    ApplicationSetting.database.cached_column_exists?(:home_page_url)
  end

  def help_page_support_url_column_exists?
    ApplicationSetting.database.cached_column_exists?(:help_page_support_url)
  end

  def disabled_oauth_sign_in_sources=(sources)
    sources = (sources || []).map(&:to_s) & Devise.omniauth_providers.map(&:to_s)
    super(sources)
  end

  def domain_allowlist_raw
    array_to_string(domain_allowlist)
  end

  def domain_denylist_raw
    array_to_string(domain_denylist)
  end

  def domain_allowlist_raw=(values)
    self.domain_allowlist = strings_to_array(values)
  end

  def domain_denylist_raw=(values)
    self.domain_denylist = strings_to_array(values)
  end

  def domain_denylist_file=(file)
    self.domain_denylist_raw = file.read
  end

  def outbound_local_requests_allowlist_raw
    array_to_string(outbound_local_requests_whitelist)
  end

  def outbound_local_requests_allowlist_raw=(values)
    clear_memoization(:outbound_local_requests_allowlist_arrays)

    self.outbound_local_requests_whitelist = strings_to_array(values)
  end

  def add_to_outbound_local_requests_whitelist(values_array)
    clear_memoization(:outbound_local_requests_allowlist_arrays)

    self.outbound_local_requests_whitelist ||= []
    self.outbound_local_requests_whitelist += values_array

    self.outbound_local_requests_whitelist.uniq!
  end

  # This method separates out the strings stored in the
  # application_setting.outbound_local_requests_whitelist array into 2 arrays;
  # an array of IPAddr objects (`[IPAddr.new('127.0.0.1')]`), and an array of
  # domain strings (`['www.example.com']`).
  def outbound_local_requests_allowlist_arrays
    strong_memoize(:outbound_local_requests_allowlist_arrays) do
      next [[], []] unless self.outbound_local_requests_whitelist

      ip_allowlist, domain_allowlist = separate_allowlists(self.outbound_local_requests_whitelist)

      [ip_allowlist, domain_allowlist]
    end
  end

  def protected_paths_raw
    array_to_string(protected_paths)
  end

  def protected_paths_raw=(values)
    self.protected_paths = strings_to_array(values)
  end

  def protected_paths_for_get_request_raw
    array_to_string(protected_paths_for_get_request)
  end

  def protected_paths_for_get_request_raw=(values)
    self.protected_paths_for_get_request = strings_to_array(values)
  end

  def notes_create_limit_allowlist_raw
    array_to_string(notes_create_limit_allowlist)
  end

  def notes_create_limit_allowlist_raw=(values)
    self.notes_create_limit_allowlist = strings_to_array(values).map(&:downcase)
  end

  def users_get_by_id_limit_allowlist_raw
    array_to_string(users_get_by_id_limit_allowlist)
  end

  def users_get_by_id_limit_allowlist_raw=(values)
    self.users_get_by_id_limit_allowlist = strings_to_array(values).map(&:downcase)
  end

  def search_rate_limit_allowlist_raw
    array_to_string(search_rate_limit_allowlist)
  end

  def search_rate_limit_allowlist_raw=(values)
    self.search_rate_limit_allowlist = strings_to_array(values).map(&:downcase)
  end

  def asset_proxy_whitelist=(values)
    values = strings_to_array(values) if values.is_a?(String)

    # make sure we always allow the running host
    values << Gitlab.config.gitlab.host unless values.include?(Gitlab.config.gitlab.host)

    self[:asset_proxy_whitelist] = values
  end
  alias_method :asset_proxy_allowlist=, :asset_proxy_whitelist=

  def asset_proxy_allowlist
    read_attribute(:asset_proxy_whitelist)
  end

  def commit_email_hostname
    super.presence || self.class.default_commit_email_hostname
  end

  def default_project_visibility=(level)
    super(Gitlab::VisibilityLevel.level_value(level))
  end

  def default_snippet_visibility=(level)
    super(Gitlab::VisibilityLevel.level_value(level))
  end

  def default_group_visibility=(level)
    super(Gitlab::VisibilityLevel.level_value(level))
  end

  def restricted_visibility_levels=(levels)
    super(levels&.map { |level| Gitlab::VisibilityLevel.level_value(level) })
  end

  def static_objects_external_storage_auth_token=(token)
    if token.present?
      set_static_objects_external_storage_auth_token(token)
    else
      self.static_objects_external_storage_auth_token_encrypted = nil
    end
  end

  def performance_bar_allowed_group
    Group.find_by_id(performance_bar_allowed_group_id)
  end

  # Return true if the Performance Bar is enabled for a given group
  def performance_bar_enabled
    performance_bar_allowed_group_id.present?
  end

  def normalized_repository_storage_weights
    strong_memoize(:normalized_repository_storage_weights) do
      repository_storages_weights = repository_storages_weighted.slice(*Gitlab.config.repositories.storages.keys)
      weights_total = repository_storages_weights.values.sum

      repository_storages_weights.transform_values do |w|
        next w if weights_total == 0

        w.to_f / weights_total
      end
    end
  end

  # Choose one of the available repository storage options based on a normalized weighted probability.
  def pick_repository_storage
    normalized_repository_storage_weights.max_by { |_, weight| rand**(1.0 / weight) }.first
  end

  def runners_registration_token
    return unless Gitlab::CurrentSettings.allow_runner_registration_token

    ensure_runners_registration_token!
  end

  def health_check_access_token
    ensure_health_check_access_token!
  end

  def error_tracking_access_token
    ensure_error_tracking_access_token!
  end

  def usage_ping_can_be_configured?
    Settings.gitlab.usage_ping_enabled
  end

  def usage_ping_features_enabled
    return false unless usage_ping_enabled? && super

    if Gitlab.ee? && respond_to?(:include_optional_metrics_in_service_ping)
      return include_optional_metrics_in_service_ping
    end

    true
  end

  alias_method :usage_ping_features_enabled?, :usage_ping_features_enabled

  def usage_ping_enabled
    usage_ping_can_be_configured? && super
  end

  alias_method :usage_ping_enabled?, :usage_ping_enabled

  def allowed_key_types
    Gitlab::SSHPublicKey.supported_types.select do |type|
      key_restriction_for(type) != FORBIDDEN_KEY_VALUE
    end
  end

  def key_restriction_for(type)
    attr_name = "#{type}_key_restriction"

    has_attribute?(attr_name) ? public_send(attr_name) : FORBIDDEN_KEY_VALUE # rubocop:disable GitlabSecurity/PublicSend
  end

  def allow_signup?
    signup_enabled? && password_authentication_enabled_for_web?
  end

  def password_authentication_enabled?
    password_authentication_enabled_for_web? || password_authentication_enabled_for_git?
  end

  def user_default_internal_regex_enabled?
    user_default_external? && user_default_internal_regex.present?
  end

  def user_default_internal_regex_instance
    Regexp.new(user_default_internal_regex, Regexp::IGNORECASE)
  end

  delegate :terms, to: :latest_terms, allow_nil: true
  def latest_terms
    @latest_terms ||= ApplicationSetting::Term.latest
  end

  def reset_memoized_terms
    @latest_terms = nil # rubocop:disable Gitlab/ModuleWithInstanceVariables
    latest_terms
  end

  def archive_builds_older_than
    archive_builds_in_seconds.seconds.ago if archive_builds_in_seconds
  end

  def static_objects_external_storage_enabled?
    static_objects_external_storage_url.present?
  end

  def ensure_key_restrictions!
    return if Gitlab::Database.read_only?
    return unless Gitlab::FIPS.enabled?

    Gitlab::SSHPublicKey.supported_types.each do |key_type|
      set_max_key_restriction!(key_type)
    end
  end

  def repository_storages_with_default_weight
    # config file config/gitlab.yml becomes SSOT for this API
    # see https://gitlab.com/gitlab-org/gitlab/-/issues/426091#note_1675160909
    storages_map = Gitlab.config.repositories.storages.keys.map do |storage|
      [storage, repository_storages_weighted[storage] || 0]
    end

    Hash[storages_map]
  end

  private

  def set_max_key_restriction!(key_type)
    attr_name = "#{key_type}_key_restriction"
    current = attributes[attr_name].to_i

    return if current == KeyRestrictionValidator::FORBIDDEN

    min_size = self.class.default_min_key_size(key_type)

    new_value =
      if min_size == KeyRestrictionValidator::FORBIDDEN
        min_size
      else
        [min_size, current].max
      end

    assign_attributes({ attr_name => new_value })
  end

  def separate_allowlists(string_array)
    string_array.reduce([[], []]) do |(ip_allowlist, domain_allowlist), string|
      address, port = parse_addr_and_port(string)

      ip_obj = Gitlab::Utils.string_to_ip_object(address)

      if ip_obj
        ip_allowlist << Gitlab::UrlBlockers::IpAllowlistEntry.new(ip_obj, port: port)
      else
        domain_allowlist << Gitlab::UrlBlockers::DomainAllowlistEntry.new(address, port: port)
      end

      [ip_allowlist, domain_allowlist]
    end
  end

  def parse_addr_and_port(str)
    case str
    when /\A\[(?<address> .* )\]:(?<port> \d+ )\z/x      # string like "[::1]:80"
      address = $~[:address]
      port = $~[:port]
    when /\A(?<address> [^:]+ ):(?<port> \d+ )\z/x       # string like "127.0.0.1:80"
      address = $~[:address]
      port = $~[:port]
    else                                                 # string with no port number
      address = str
      port = nil
    end

    [address, port&.to_i]
  end

  def array_to_string(arr)
    arr&.join("\n")
  end

  def strings_to_array(values)
    return [] unless values

    values
      .split(STRING_LIST_SEPARATOR)
      .map(&:strip)
      .reject(&:empty?)
      .uniq
  end

  def ensure_uuid!
    return if uuid?

    self.uuid = SecureRandom.uuid
  end

  def coerce_repository_storages_weighted
    repository_storages_weighted.transform_values!(&:to_i)
  end

  def check_repository_storages_weighted
    invalid = repository_storages_weighted.keys - Gitlab.config.repositories.storages.keys
    errors.add(:repository_storages_weighted, _("can't include: %{invalid_storages}") % { invalid_storages: invalid.join(", ") }) unless
      invalid.empty?

    repository_storages_weighted.each do |key, val|
      next unless val.present?

      unless val.is_a?(Integer)
        errors.add(:repository_storages_weighted, _("value for '%{storage}' must be an integer") % { storage: key })
      end

      unless val.between?(0, 100)
        errors.add(:repository_storages_weighted, _("value for '%{storage}' must be between 0 and 100") % { storage: key })
      end
    end
  end

  def check_valid_runner_registrars
    return if valid_runner_registrar_combinations.include?(valid_runner_registrars)

    errors.add(:valid_runner_registrars, _("%{value} is not included in the list") % { value: valid_runner_registrars })
  end

  def valid_runner_registrar_combinations
    0.upto(VALID_RUNNER_REGISTRAR_TYPES.size).flat_map do |n|
      VALID_RUNNER_REGISTRAR_TYPES.permutation(n).to_a
    end
  end

  def terms_exist
    return unless enforce_terms?

    errors.add(:base, _('You need to set terms to be enforced')) unless terms.present?
  end

  def expire_performance_bar_allowed_user_ids_cache
    Gitlab::PerformanceBar.expire_allowed_user_ids_cache
  end
end
