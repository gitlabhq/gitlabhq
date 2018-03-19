class ApplicationSetting < ActiveRecord::Base
  include CacheMarkdownField
  include TokenAuthenticatable
  prepend EE::ApplicationSetting

  add_authentication_token_field :runners_registration_token
  add_authentication_token_field :health_check_access_token

  CACHE_KEY = 'application_setting.last'.freeze
  DOMAIN_LIST_SEPARATOR = %r{\s*[,;]\s*     # comma or semicolon, optionally surrounded by whitespace
                            |               # or
                            \s              # any whitespace character
                            |               # or
                            [\r\n]          # any number of newline characters
                          }x

  # Setting a key restriction to `-1` means that all keys of this type are
  # forbidden.
  FORBIDDEN_KEY_VALUE = KeyRestrictionValidator::FORBIDDEN
  SUPPORTED_KEY_TYPES = %i[rsa dsa ecdsa ed25519].freeze

  serialize :restricted_visibility_levels # rubocop:disable Cop/ActiveRecordSerialize
  serialize :import_sources # rubocop:disable Cop/ActiveRecordSerialize
  serialize :disabled_oauth_sign_in_sources, Array # rubocop:disable Cop/ActiveRecordSerialize
  serialize :domain_whitelist, Array # rubocop:disable Cop/ActiveRecordSerialize
  serialize :domain_blacklist, Array # rubocop:disable Cop/ActiveRecordSerialize
  serialize :repository_storages # rubocop:disable Cop/ActiveRecordSerialize
  serialize :sidekiq_throttling_queues, Array # rubocop:disable Cop/ActiveRecordSerialize

  cache_markdown_field :sign_in_text
  cache_markdown_field :help_page_text
  cache_markdown_field :shared_runners_text, pipeline: :plain_markdown
  cache_markdown_field :after_sign_up_text

  attr_accessor :domain_whitelist_raw, :domain_blacklist_raw

  default_value_for :id, 1

  validates :uuid, presence: true

  validates :session_expire_delay,
            presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  validates :home_page_url,
            allow_blank: true,
            url: true,
            if: :home_page_url_column_exists?

  validates :help_page_support_url,
            allow_blank: true,
            url: true,
            if: :help_page_support_url_column_exists?

  validates :after_sign_out_path,
            allow_blank: true,
            url: true

  validates :admin_notification_email,
            email: true,
            allow_blank: true

  validates :two_factor_grace_period,
            numericality: { greater_than_or_equal_to: 0 }

  validates :recaptcha_site_key,
            presence: true,
            if: :recaptcha_enabled

  validates :recaptcha_private_key,
            presence: true,
            if: :recaptcha_enabled

  validates :sentry_dsn,
            presence: true,
            if: :sentry_enabled

  validates :clientside_sentry_dsn,
            presence: true,
            if: :clientside_sentry_enabled

  validates :akismet_api_key,
            presence: true,
            if: :akismet_enabled

  validates :unique_ips_limit_per_user,
            numericality: { greater_than_or_equal_to: 1 },
            presence: true,
            if: :unique_ips_limit_enabled

  validates :unique_ips_limit_time_window,
            numericality: { greater_than_or_equal_to: 0 },
            presence: true,
            if: :unique_ips_limit_enabled

  validates :koding_url,
            presence: true,
            if: :koding_enabled

  validates :plantuml_url,
            presence: true,
            if: :plantuml_enabled

  validates :max_attachment_size,
            presence: true,
            numericality: { only_integer: true, greater_than: 0 }

  validates :max_artifacts_size,
            presence: true,
            numericality: { only_integer: true, greater_than: 0 }

  validates :default_artifacts_expire_in, presence: true, duration: true

  validates :container_registry_token_expire_delay,
            presence: true,
            numericality: { only_integer: true, greater_than: 0 }

  validates :repository_storages, presence: true
  validate :check_repository_storages

  validates :auto_devops_domain,
            allow_blank: true,
            hostname: { allow_numeric_hostname: true, require_valid_tld: true },
            if: :auto_devops_enabled?

  validates :enabled_git_access_protocol,
            inclusion: { in: %w(ssh http), allow_blank: true, allow_nil: true }

  validates :domain_blacklist,
            presence: { message: 'Domain blacklist cannot be empty if Blacklist is enabled.' },
            if: :domain_blacklist_enabled?

  validates :sidekiq_throttling_factor,
            numericality: { greater_than: 0, less_than: 1 },
            presence: { message: 'Throttling factor cannot be empty if Sidekiq Throttling is enabled.' },
            if: :sidekiq_throttling_enabled?

  validates :sidekiq_throttling_queues,
            presence: { message: 'Queues to throttle cannot be empty if Sidekiq Throttling is enabled.' },
            if: :sidekiq_throttling_enabled?

  validates :housekeeping_incremental_repack_period,
            presence: true,
            numericality: { only_integer: true, greater_than: 0 }

  validates :housekeeping_full_repack_period,
            presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: :housekeeping_incremental_repack_period }

  validates :housekeeping_gc_period,
            presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: :housekeeping_full_repack_period }

  validates :terminal_max_session_time,
            presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  validates :polling_interval_multiplier,
            presence: true,
            numericality: { greater_than_or_equal_to: 0 }

  validates :circuitbreaker_failure_count_threshold,
            :circuitbreaker_failure_reset_time,
            :circuitbreaker_storage_timeout,
            :circuitbreaker_check_interval,
            presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  validates :circuitbreaker_access_retries,
            presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 1 }

  validates :gitaly_timeout_default,
            presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  validates :gitaly_timeout_medium,
            presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :gitaly_timeout_medium,
            numericality: { less_than_or_equal_to: :gitaly_timeout_default },
            if: :gitaly_timeout_default
  validates :gitaly_timeout_medium,
            numericality: { greater_than_or_equal_to: :gitaly_timeout_fast },
            if: :gitaly_timeout_fast

  validates :gitaly_timeout_fast,
            presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :gitaly_timeout_fast,
            numericality: { less_than_or_equal_to: :gitaly_timeout_default },
            if: :gitaly_timeout_default

  SUPPORTED_KEY_TYPES.each do |type|
    validates :"#{type}_key_restriction", presence: true, key_restriction: { type: type }
  end

  validates :allowed_key_types, presence: true

  validates_each :restricted_visibility_levels do |record, attr, value|
    value&.each do |level|
      unless Gitlab::VisibilityLevel.options.value?(level)
        record.errors.add(attr, "'#{level}' is not a valid visibility level")
      end
    end
  end

  validates_each :import_sources do |record, attr, value|
    value&.each do |source|
      unless Gitlab::ImportSources.options.value?(source)
        record.errors.add(attr, "'#{source}' is not a import source")
      end
    end
  end

  validates_each :disabled_oauth_sign_in_sources do |record, attr, value|
    value&.each do |source|
      unless Devise.omniauth_providers.include?(source.to_sym)
        record.errors.add(attr, "'#{source}' is not an OAuth sign-in source")
      end
    end
  end

  before_validation :ensure_uuid!

  before_save :ensure_runners_registration_token
  before_save :ensure_health_check_access_token

  after_commit do
    Rails.cache.write(CACHE_KEY, self)
  end

  def self.current
    ensure_cache_setup

    Rails.cache.fetch(CACHE_KEY) do
      ApplicationSetting.last.tap do |settings|
        # do not cache nils
        raise 'missing settings' unless settings
      end
    end
  rescue
    # Fall back to an uncached value if there are any problems (e.g. redis down)
    ApplicationSetting.last
  end

  def self.expire
    Rails.cache.delete(CACHE_KEY)
  rescue
    # Gracefully handle when Redis is not available. For example,
    # omnibus may fail here during gitlab:assets:compile.
  end

  def self.cached
    value = Rails.cache.read(CACHE_KEY)
    ensure_cache_setup if value.present?
    value
  end

  def self.ensure_cache_setup
    # This is a workaround for a Rails bug that causes attribute methods not
    # to be loaded when read from cache: https://github.com/rails/rails/issues/27348
    ApplicationSetting.define_attribute_methods
  end

  def self.defaults
    {
      after_sign_up_text: nil,
      akismet_enabled: false,
      authorized_keys_enabled: true, # TODO default to false if the instance is configured to use AuthorizedKeysCommand
      container_registry_token_expire_delay: 5,
      default_artifacts_expire_in: '30 days',
      default_branch_protection: Settings.gitlab['default_branch_protection'],
      default_project_visibility: Settings.gitlab.default_projects_features['visibility_level'],
      default_projects_limit: Settings.gitlab['default_projects_limit'],
      default_snippet_visibility: Settings.gitlab.default_projects_features['visibility_level'],
      default_group_visibility: Settings.gitlab.default_projects_features['visibility_level'],
      disabled_oauth_sign_in_sources: [],
      domain_whitelist: Settings.gitlab['domain_whitelist'],
      dsa_key_restriction: 0,
      ecdsa_key_restriction: 0,
      ed25519_key_restriction: 0,
      gravatar_enabled: Settings.gravatar['enabled'],
      help_page_text: nil,
      help_page_hide_commercial_content: false,
      unique_ips_limit_per_user: 10,
      unique_ips_limit_time_window: 3600,
      unique_ips_limit_enabled: false,
      housekeeping_bitmaps_enabled: true,
      housekeeping_enabled: true,
      housekeeping_full_repack_period: 50,
      housekeeping_gc_period: 200,
      housekeeping_incremental_repack_period: 10,
      import_sources: Settings.gitlab['import_sources'],
      koding_enabled: false,
      koding_url: nil,
      max_artifacts_size: Settings.artifacts['max_size'],
      max_attachment_size: Settings.gitlab['max_attachment_size'],
      password_authentication_enabled_for_web: Settings.gitlab['signin_enabled'],
      password_authentication_enabled_for_git: true,
      performance_bar_allowed_group_id: nil,
      rsa_key_restriction: 0,
      plantuml_enabled: false,
      plantuml_url: nil,
      project_export_enabled: true,
      recaptcha_enabled: false,
      repository_checks_enabled: true,
      repository_storages: ['default'],
      require_two_factor_authentication: false,
      restricted_visibility_levels: Settings.gitlab['restricted_visibility_levels'],
      session_expire_delay: Settings.gitlab['session_expire_delay'],
      send_user_confirmation_email: false,
      shared_runners_enabled: Settings.gitlab_ci['shared_runners_enabled'],
      shared_runners_text: nil,
      sidekiq_throttling_enabled: false,
      sign_in_text: nil,
      signup_enabled: Settings.gitlab['signup_enabled'],
      terminal_max_session_time: 0,
      throttle_unauthenticated_enabled: false,
      throttle_unauthenticated_requests_per_period: 3600,
      throttle_unauthenticated_period_in_seconds: 3600,
      throttle_authenticated_web_enabled: false,
      throttle_authenticated_web_requests_per_period: 7200,
      throttle_authenticated_web_period_in_seconds: 3600,
      throttle_authenticated_api_enabled: false,
      throttle_authenticated_api_requests_per_period: 7200,
      throttle_authenticated_api_period_in_seconds: 3600,
      two_factor_grace_period: 48,
      user_default_external: false,
      polling_interval_multiplier: 1,
      usage_ping_enabled: Settings.gitlab['usage_ping_enabled'],
      gitaly_timeout_fast: 10,
      gitaly_timeout_medium: 30,
      gitaly_timeout_default: 55
    }
  end

  def self.create_from_defaults
    create(defaults)
  end

  def self.human_attribute_name(attr, _options = {})
    if attr == :default_artifacts_expire_in
      'Default artifacts expiration'
    else
      super
    end
  end

  def home_page_url_column_exists?
    ::Gitlab::Database.cached_column_exists?(:application_settings, :home_page_url)
  end

  def help_page_support_url_column_exists?
    ::Gitlab::Database.cached_column_exists?(:application_settings, :help_page_support_url)
  end

  def sidekiq_throttling_column_exists?
    ::Gitlab::Database.cached_column_exists?(:application_settings, :sidekiq_throttling_enabled)
  end

  def domain_whitelist_raw
    self.domain_whitelist&.join("\n")
  end

  def domain_blacklist_raw
    self.domain_blacklist&.join("\n")
  end

  def domain_whitelist_raw=(values)
    self.domain_whitelist = []
    self.domain_whitelist = values.split(DOMAIN_LIST_SEPARATOR)
    self.domain_whitelist.reject! { |d| d.empty? }
    self.domain_whitelist
  end

  def domain_blacklist_raw=(values)
    self.domain_blacklist = []
    self.domain_blacklist = values.split(DOMAIN_LIST_SEPARATOR)
    self.domain_blacklist.reject! { |d| d.empty? }
    self.domain_blacklist
  end

  def domain_blacklist_file=(file)
    self.domain_blacklist_raw = file.read
  end

  def repository_storages
    Array(read_attribute(:repository_storages))
  end

  # DEPRECATED
  # repository_storage is still required in the API. Remove in 9.0
  # Still used in API v3
  def repository_storage
    repository_storages.first
  end

  def repository_storage=(value)
    self.repository_storages = [value]
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
    super(levels.map { |level| Gitlab::VisibilityLevel.level_value(level) })
  end

  def performance_bar_allowed_group_id=(group_full_path)
    group_full_path = nil if group_full_path.blank?

    if group_full_path.nil?
      if group_full_path != performance_bar_allowed_group_id
        super(group_full_path)
        Gitlab::PerformanceBar.expire_allowed_user_ids_cache
      end

      return
    end

    group = Group.find_by_full_path(group_full_path)

    if group
      if group.id != performance_bar_allowed_group_id
        super(group.id)
        Gitlab::PerformanceBar.expire_allowed_user_ids_cache
      end
    else
      super(nil)
      Gitlab::PerformanceBar.expire_allowed_user_ids_cache
    end
  end

  def performance_bar_allowed_group
    Group.find_by_id(performance_bar_allowed_group_id)
  end

  # Return true if the Performance Bar is enabled for a given group
  def performance_bar_enabled
    performance_bar_allowed_group_id.present?
  end

  # - If `enable` is true, we early return since the actual attribute that holds
  #   the enabling/disabling is `performance_bar_allowed_group_id`
  # - If `enable` is false, we set `performance_bar_allowed_group_id` to `nil`
  def performance_bar_enabled=(enable)
    return if Gitlab::Utils.to_boolean(enable)

    self.performance_bar_allowed_group_id = nil
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

  def sidekiq_throttling_enabled?
    return false unless sidekiq_throttling_column_exists?

    sidekiq_throttling_enabled
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

  private

  def ensure_uuid!
    return if uuid?

    self.uuid = SecureRandom.uuid
  end

  def check_repository_storages
    invalid = repository_storages - Gitlab.config.repositories.storages.keys
    errors.add(:repository_storages, "can't include: #{invalid.join(", ")}") unless
      invalid.empty?
  end
end
