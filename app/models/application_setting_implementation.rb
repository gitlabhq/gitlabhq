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
        after_sign_up_text: nil,
        akismet_enabled: false,
        allow_local_requests_from_web_hooks_and_services: false,
        allow_local_requests_from_system_hooks: true,
        asset_proxy_enabled: false,
        authorized_keys_enabled: true, # TODO default to false if the instance is configured to use AuthorizedKeysCommand
        commit_email_hostname: default_commit_email_hostname,
        container_registry_token_expire_delay: 5,
        default_artifacts_expire_in: '30 days',
        default_branch_protection: Settings.gitlab['default_branch_protection'],
        default_ci_config_path: nil,
        default_group_visibility: Settings.gitlab.default_projects_features['visibility_level'],
        default_project_creation: Settings.gitlab['default_project_creation'],
        default_project_visibility: Settings.gitlab.default_projects_features['visibility_level'],
        default_projects_limit: Settings.gitlab['default_projects_limit'],
        default_snippet_visibility: Settings.gitlab.default_projects_features['visibility_level'],
        diff_max_patch_bytes: Gitlab::Git::Diff::DEFAULT_MAX_PATCH_BYTES,
        disabled_oauth_sign_in_sources: [],
        dns_rebinding_protection_enabled: true,
        domain_whitelist: Settings.gitlab['domain_whitelist'],
        dsa_key_restriction: 0,
        ecdsa_key_restriction: 0,
        ed25519_key_restriction: 0,
        eks_integration_enabled: false,
        eks_account_id: nil,
        eks_access_key_id: nil,
        eks_secret_access_key: nil,
        first_day_of_week: 0,
        gitaly_timeout_default: 55,
        gitaly_timeout_fast: 10,
        gitaly_timeout_medium: 30,
        gravatar_enabled: Settings.gravatar['enabled'],
        help_page_hide_commercial_content: false,
        help_page_text: nil,
        hide_third_party_offers: false,
        housekeeping_bitmaps_enabled: true,
        housekeeping_enabled: true,
        housekeeping_full_repack_period: 50,
        housekeeping_gc_period: 200,
        housekeeping_incremental_repack_period: 10,
        import_sources: Settings.gitlab['import_sources'],
        local_markdown_version: 0,
        max_artifacts_size: Settings.artifacts['max_size'],
        max_attachment_size: Settings.gitlab['max_attachment_size'],
        mirror_available: true,
        outbound_local_requests_whitelist: [],
        password_authentication_enabled_for_git: true,
        password_authentication_enabled_for_web: Settings.gitlab['signin_enabled'],
        performance_bar_allowed_group_id: nil,
        rsa_key_restriction: 0,
        plantuml_enabled: false,
        plantuml_url: nil,
        polling_interval_multiplier: 1,
        project_export_enabled: true,
        protected_ci_variables: false,
        push_event_hooks_limit: 3,
        push_event_activities_limit: 3,
        raw_blob_request_limit: 300,
        recaptcha_enabled: false,
        login_recaptcha_protection_enabled: false,
        repository_checks_enabled: true,
        repository_storages: ['default'],
        require_two_factor_authentication: false,
        restricted_visibility_levels: Settings.gitlab['restricted_visibility_levels'],
        session_expire_delay: Settings.gitlab['session_expire_delay'],
        send_user_confirmation_email: false,
        shared_runners_enabled: Settings.gitlab_ci['shared_runners_enabled'],
        shared_runners_text: nil,
        sign_in_text: nil,
        signup_enabled: Settings.gitlab['signup_enabled'],
        sourcegraph_enabled: false,
        sourcegraph_url: nil,
        sourcegraph_public_only: true,
        minimum_password_length: DEFAULT_MINIMUM_PASSWORD_LENGTH,
        terminal_max_session_time: 0,
        throttle_authenticated_api_enabled: false,
        throttle_authenticated_api_period_in_seconds: 3600,
        throttle_authenticated_api_requests_per_period: 7200,
        throttle_authenticated_web_enabled: false,
        throttle_authenticated_web_period_in_seconds: 3600,
        throttle_authenticated_web_requests_per_period: 7200,
        throttle_unauthenticated_enabled: false,
        throttle_unauthenticated_period_in_seconds: 3600,
        throttle_unauthenticated_requests_per_period: 3600,
        throttle_protected_paths_enabled: false,
        throttle_protected_paths_in_seconds: 10,
        throttle_protected_paths_per_period: 60,
        protected_paths: DEFAULT_PROTECTED_PATHS,
        throttle_incident_management_notification_enabled: false,
        throttle_incident_management_notification_period_in_seconds: 3600,
        throttle_incident_management_notification_per_period: 3600,
        time_tracking_limit_to_hours: false,
        two_factor_grace_period: 48,
        unique_ips_limit_enabled: false,
        unique_ips_limit_per_user: 10,
        unique_ips_limit_time_window: 3600,
        usage_ping_enabled: Settings.gitlab['usage_ping_enabled'],
        instance_statistics_visibility_private: false,
        user_default_external: false,
        user_default_internal_regex: nil,
        user_show_add_ssh_key_message: true,
        usage_stats_set_by_user_id: nil,
        snowplow_collector_hostname: nil,
        snowplow_cookie_domain: nil,
        snowplow_enabled: false,
        snowplow_app_id: nil,
        snowplow_iglu_registry_url: nil,
        custom_http_clone_url_root: nil,
        productivity_analytics_start_date: Time.now,
        snippet_size_limit: 50.megabytes
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

  def domain_whitelist_raw
    array_to_string(self.domain_whitelist)
  end

  def domain_blacklist_raw
    array_to_string(self.domain_blacklist)
  end

  def domain_whitelist_raw=(values)
    self.domain_whitelist = strings_to_array(values)
  end

  def domain_blacklist_raw=(values)
    self.domain_blacklist = strings_to_array(values)
  end

  def domain_blacklist_file=(file)
    self.domain_blacklist_raw = file.read
  end

  def outbound_local_requests_whitelist_raw
    array_to_string(self.outbound_local_requests_whitelist)
  end

  def outbound_local_requests_whitelist_raw=(values)
    clear_memoization(:outbound_local_requests_whitelist_arrays)

    self.outbound_local_requests_whitelist = strings_to_array(values)
  end

  def add_to_outbound_local_requests_whitelist(values_array)
    clear_memoization(:outbound_local_requests_whitelist_arrays)

    self.outbound_local_requests_whitelist ||= []
    self.outbound_local_requests_whitelist += values_array

    self.outbound_local_requests_whitelist.uniq!
  end

  def outbound_local_requests_whitelist_arrays
    strong_memoize(:outbound_local_requests_whitelist_arrays) do
      next [[], []] unless self.outbound_local_requests_whitelist

      ip_whitelist = []
      domain_whitelist = []

      self.outbound_local_requests_whitelist.each do |str|
        ip_obj = Gitlab::Utils.string_to_ip_object(str)

        if ip_obj
          ip_whitelist << ip_obj
        else
          domain_whitelist << str
        end
      end

      [ip_whitelist, domain_whitelist]
    end
  end

  def protected_paths_raw
    array_to_string(self.protected_paths)
  end

  def protected_paths_raw=(values)
    self.protected_paths = strings_to_array(values)
  end

  def asset_proxy_whitelist=(values)
    values = strings_to_array(values) if values.is_a?(String)

    # make sure we always whitelist the running host
    values << Gitlab.config.gitlab.host unless values.include?(Gitlab.config.gitlab.host)

    self[:asset_proxy_whitelist] = values
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

  # Choose one of the available repository storage options. Currently all have
  # equal weighting.
  def pick_repository_storage
    repository_storages.sample
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

  def usage_ping_enabled
    usage_ping_can_be_configured? && super
  end

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

  private

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

  def terms_exist
    return unless enforce_terms?

    errors.add(:terms, "You need to set terms to be enforced") unless terms.present?
  end

  def expire_performance_bar_allowed_user_ids_cache
    Gitlab::PerformanceBar.expire_allowed_user_ids_cache
  end
end
