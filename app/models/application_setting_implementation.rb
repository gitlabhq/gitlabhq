# frozen_string_literal: true

module ApplicationSettingImplementation
  extend ActiveSupport::Concern
  include Gitlab::Utils::StrongMemoize

  STRING_LIST_SEPARATOR = %r{\s*[,;]\s*     # comma or semicolon, optionally surrounded by whitespace
                            |               # or
                            \s              # any whitespace character
                            |               # or
                            [\r\n]          # any number of newline characters
                          }x.freeze

  # Setting a key restriction to `-1` means that all keys of this type are
  # forbidden.
  FORBIDDEN_KEY_VALUE = KeyRestrictionValidator::FORBIDDEN
  SUPPORTED_KEY_TYPES = %i[rsa dsa ecdsa ed25519].freeze
  VALID_RUNNER_REGISTRAR_TYPES = %w(project group).freeze

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
    def defaults
      {
        admin_mode: false,
        after_sign_up_text: nil,
        akismet_enabled: false,
        akismet_api_key: nil,
        allow_local_requests_from_system_hooks: true,
        allow_local_requests_from_web_hooks_and_services: false,
        asset_proxy_enabled: false,
        authorized_keys_enabled: true, # TODO default to false if the instance is configured to use AuthorizedKeysCommand
        commit_email_hostname: default_commit_email_hostname,
        container_expiration_policies_enable_historic_entries: false,
        container_registry_features: [],
        container_registry_token_expire_delay: 5,
        container_registry_vendor: '',
        container_registry_version: '',
        custom_http_clone_url_root: nil,
        default_artifacts_expire_in: '30 days',
        default_branch_name: nil,
        default_branch_protection: Settings.gitlab['default_branch_protection'],
        default_ci_config_path: nil,
        default_group_visibility: Settings.gitlab.default_projects_features['visibility_level'],
        default_project_creation: Settings.gitlab['default_project_creation'],
        default_project_visibility: Settings.gitlab.default_projects_features['visibility_level'],
        default_projects_limit: Settings.gitlab['default_projects_limit'],
        default_snippet_visibility: Settings.gitlab.default_projects_features['visibility_level'],
        diff_max_patch_bytes: Gitlab::Git::Diff::DEFAULT_MAX_PATCH_BYTES,
        diff_max_files: Commit::DEFAULT_MAX_DIFF_FILES_SETTING,
        diff_max_lines: Commit::DEFAULT_MAX_DIFF_LINES_SETTING,
        disable_feed_token: false,
        disabled_oauth_sign_in_sources: [],
        dns_rebinding_protection_enabled: true,
        domain_allowlist: Settings.gitlab['domain_allowlist'],
        dsa_key_restriction: 0,
        ecdsa_key_restriction: 0,
        ed25519_key_restriction: 0,
        eks_access_key_id: nil,
        eks_account_id: nil,
        eks_integration_enabled: false,
        eks_secret_access_key: nil,
        email_restrictions_enabled: false,
        email_restrictions: nil,
        external_pipeline_validation_service_timeout: nil,
        external_pipeline_validation_service_token: nil,
        external_pipeline_validation_service_url: nil,
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
        help_page_documentation_base_url: nil,
        hide_third_party_offers: false,
        housekeeping_bitmaps_enabled: true,
        housekeeping_enabled: true,
        housekeeping_full_repack_period: 50,
        housekeeping_gc_period: 200,
        housekeeping_incremental_repack_period: 10,
        import_sources: Settings.gitlab['import_sources'],
        invisible_captcha_enabled: false,
        issues_create_limit: 300,
        local_markdown_version: 0,
        login_recaptcha_protection_enabled: false,
        mailgun_signing_key: nil,
        mailgun_events_enabled: false,
        max_artifacts_size: Settings.artifacts['max_size'],
        max_attachment_size: Settings.gitlab['max_attachment_size'],
        max_import_size: 0,
        minimum_password_length: DEFAULT_MINIMUM_PASSWORD_LENGTH,
        mirror_available: true,
        notes_create_limit: 300,
        notes_create_limit_allowlist: [],
        notify_on_unknown_sign_in: true,
        outbound_local_requests_whitelist: [],
        password_authentication_enabled_for_git: true,
        password_authentication_enabled_for_web: Settings.gitlab['signin_enabled'],
        performance_bar_allowed_group_id: nil,
        personal_access_token_prefix: nil,
        plantuml_enabled: false,
        plantuml_url: nil,
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
        repository_checks_enabled: true,
        repository_storages_weighted: { 'default' => 100 },
        repository_storages: ['default'],
        require_admin_approval_after_user_signup: true,
        require_two_factor_authentication: false,
        restricted_visibility_levels: Settings.gitlab['restricted_visibility_levels'],
        rsa_key_restriction: 0,
        send_user_confirmation_email: false,
        session_expire_delay: Settings.gitlab['session_expire_delay'],
        shared_runners_enabled: Settings.gitlab_ci['shared_runners_enabled'],
        shared_runners_text: nil,
        sign_in_text: nil,
        signup_enabled: Settings.gitlab['signup_enabled'],
        snippet_size_limit: 50.megabytes,
        snowplow_app_id: nil,
        snowplow_collector_hostname: nil,
        snowplow_cookie_domain: nil,
        snowplow_enabled: false,
        sourcegraph_enabled: false,
        sourcegraph_public_only: true,
        sourcegraph_url: nil,
        spam_check_endpoint_enabled: false,
        spam_check_endpoint_url: nil,
        spam_check_api_key: nil,
        terminal_max_session_time: 0,
        throttle_authenticated_api_enabled: false,
        throttle_authenticated_api_period_in_seconds: 3600,
        throttle_authenticated_api_requests_per_period: 7200,
        throttle_authenticated_web_enabled: false,
        throttle_authenticated_web_period_in_seconds: 3600,
        throttle_authenticated_web_requests_per_period: 7200,
        throttle_authenticated_packages_api_enabled: false,
        throttle_authenticated_packages_api_period_in_seconds: 15,
        throttle_authenticated_packages_api_requests_per_period: 1000,
        throttle_incident_management_notification_enabled: false,
        throttle_incident_management_notification_per_period: 3600,
        throttle_incident_management_notification_period_in_seconds: 3600,
        throttle_protected_paths_enabled: false,
        throttle_protected_paths_in_seconds: 10,
        throttle_protected_paths_per_period: 60,
        throttle_unauthenticated_enabled: false,
        throttle_unauthenticated_period_in_seconds: 3600,
        throttle_unauthenticated_requests_per_period: 3600,
        throttle_unauthenticated_packages_api_enabled: false,
        throttle_unauthenticated_packages_api_period_in_seconds: 15,
        throttle_unauthenticated_packages_api_requests_per_period: 800,
        time_tracking_limit_to_hours: false,
        two_factor_grace_period: 48,
        unique_ips_limit_enabled: false,
        unique_ips_limit_per_user: 10,
        unique_ips_limit_time_window: 3600,
        usage_ping_enabled: Settings.gitlab['usage_ping_enabled'],
        usage_stats_set_by_user_id: nil,
        user_default_external: false,
        user_default_internal_regex: nil,
        user_show_add_ssh_key_message: true,
        valid_runner_registrars: VALID_RUNNER_REGISTRAR_TYPES,
        wiki_page_max_content_bytes: 50.megabytes,
        container_registry_delete_tags_service_timeout: 250,
        container_registry_expiration_policies_worker_capacity: 0,
        kroki_enabled: false,
        kroki_url: nil,
        kroki_formats: { blockdiag: false, bpmn: false, excalidraw: false },
        rate_limiting_response_text: nil,
        whats_new_variant: 0
      }
    end

    def default_commit_email_hostname
      "users.noreply.#{Gitlab.config.gitlab.host}"
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
    ::Gitlab::Database.cached_column_exists?(:application_settings, :home_page_url)
  end

  def help_page_support_url_column_exists?
    ::Gitlab::Database.cached_column_exists?(:application_settings, :help_page_support_url)
  end

  def disabled_oauth_sign_in_sources=(sources)
    sources = (sources || []).map(&:to_s) & Devise.omniauth_providers.map(&:to_s)
    super(sources)
  end

  def domain_allowlist_raw
    array_to_string(self.domain_allowlist)
  end

  def domain_denylist_raw
    array_to_string(self.domain_denylist)
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
    array_to_string(self.outbound_local_requests_whitelist)
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
    array_to_string(self.protected_paths)
  end

  def protected_paths_raw=(values)
    self.protected_paths = strings_to_array(values)
  end

  def notes_create_limit_allowlist_raw
    array_to_string(self.notes_create_limit_allowlist)
  end

  def notes_create_limit_allowlist_raw=(values)
    self.notes_create_limit_allowlist = strings_to_array(values).map(&:downcase)
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

  def repository_storages
    Array(read_attribute(:repository_storages))
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
      weights_total = repository_storages_weights.values.reduce(:+)

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
    ensure_runners_registration_token!
  end

  def health_check_access_token
    ensure_health_check_access_token!
  end

  def usage_ping_can_be_configured?
    Settings.gitlab.usage_ping_enabled
  end

  def usage_ping_features_enabled?
    usage_ping_enabled? && usage_ping_features_enabled
  end

  def usage_ping_enabled
    usage_ping_can_be_configured? && super
  end
  alias_method :usage_ping_enabled?, :usage_ping_enabled

  def allowed_key_types
    SUPPORTED_KEY_TYPES.select do |type|
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

  # This will eventually be configurable
  # https://gitlab.com/gitlab-org/gitlab/issues/208161
  def web_ide_clientside_preview_bundler_url
    'https://sandbox-prod.gitlab-static.net'
  end

  private

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

  def check_repository_storages
    invalid = repository_storages - Gitlab.config.repositories.storages.keys
    errors.add(:repository_storages, "can't include: #{invalid.join(", ")}") unless
      invalid.empty?
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

      errors.add(:repository_storages_weighted, _("value for '%{storage}' must be an integer") % { storage: key }) unless val.is_a?(Integer)
      errors.add(:repository_storages_weighted, _("value for '%{storage}' must be between 0 and 100") % { storage: key }) unless val.between?(0, 100)
    end
  end

  def check_valid_runner_registrars
    valid = valid_runner_registrar_combinations.include?(valid_runner_registrars)
    errors.add(:valid_runner_registrars, _("%{value} is not included in the list") % { value: valid_runner_registrars }) unless valid
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
