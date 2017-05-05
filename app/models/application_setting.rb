class ApplicationSetting < ActiveRecord::Base
  include CacheMarkdownField
  include TokenAuthenticatable

  add_authentication_token_field :runners_registration_token
  add_authentication_token_field :health_check_access_token

  CACHE_KEY = 'application_setting.last'.freeze
  DOMAIN_LIST_SEPARATOR = %r{\s*[,;]\s*     # comma or semicolon, optionally surrounded by whitespace
                            |               # or
                            \s              # any whitespace character
                            |               # or
                            [\r\n]          # any number of newline characters
                          }x

  serialize :restricted_visibility_levels
  serialize :import_sources
  serialize :disabled_oauth_sign_in_sources, Array
  serialize :domain_whitelist, Array
  serialize :domain_blacklist, Array
  serialize :repository_storages
  serialize :sidekiq_throttling_queues, Array

  cache_markdown_field :sign_in_text
  cache_markdown_field :help_page_text
  cache_markdown_field :shared_runners_text, pipeline: :plain_markdown
  cache_markdown_field :after_sign_up_text

  attr_accessor :domain_whitelist_raw, :domain_blacklist_raw

  validates :uuid, presence: true

  validates :session_expire_delay,
            presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  validates :home_page_url,
            allow_blank: true,
            url: true,
            if: :home_page_url_column_exist

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
            numericality: { only_integer: true, greater_than: :housekeeping_incremental_repack_period }

  validates :housekeeping_gc_period,
            presence: true,
            numericality: { only_integer: true, greater_than: :housekeeping_full_repack_period }

  validates :terminal_max_session_time,
            presence: true,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  validates :polling_interval_multiplier,
            presence: true,
            numericality: { greater_than_or_equal_to: 0 }

  validates_each :restricted_visibility_levels do |record, attr, value|
    value&.each do |level|
      unless Gitlab::VisibilityLevel.options.has_value?(level)
        record.errors.add(attr, "'#{level}' is not a valid visibility level")
      end
    end
  end

  validates_each :import_sources do |record, attr, value|
    value&.each do |source|
      unless Gitlab::ImportSources.options.has_value?(source)
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
      ApplicationSetting.last
    end
  end

  def self.expire
    Rails.cache.delete(CACHE_KEY)
  rescue
    # Gracefully handle when Redis is not available. For example,
    # omnibus may fail here during gitlab:assets:compile.
  end

  def self.cached
    ensure_cache_setup
    Rails.cache.fetch(CACHE_KEY)
  end

  def self.ensure_cache_setup
    # This is a workaround for a Rails bug that causes attribute methods not
    # to be loaded when read from cache: https://github.com/rails/rails/issues/27348
    ApplicationSetting.define_attribute_methods
  end

  def self.defaults_ce
    {
      after_sign_up_text: nil,
      akismet_enabled: false,
      container_registry_token_expire_delay: 5,
      default_artifacts_expire_in: '30 days',
      default_branch_protection: Settings.gitlab['default_branch_protection'],
      default_project_visibility: Settings.gitlab.default_projects_features['visibility_level'],
      default_projects_limit: Settings.gitlab['default_projects_limit'],
      default_snippet_visibility: Settings.gitlab.default_projects_features['visibility_level'],
      default_group_visibility: Settings.gitlab.default_projects_features['visibility_level'],
      disabled_oauth_sign_in_sources: [],
      domain_whitelist: Settings.gitlab['domain_whitelist'],
      gravatar_enabled: Settings.gravatar['enabled'],
      help_page_text: nil,
      unique_ips_limit_per_user: 10,
      unique_ips_limit_time_window: 3600,
      unique_ips_limit_enabled: false,
      housekeeping_bitmaps_enabled: true,
      housekeeping_enabled: true,
      housekeeping_full_repack_period: 50,
      housekeeping_gc_period: 200,
      housekeeping_incremental_repack_period: 10,
      import_sources: Gitlab::ImportSources.values,
      koding_enabled: false,
      koding_url: nil,
      max_artifacts_size: Settings.artifacts['max_size'],
      max_attachment_size: Settings.gitlab['max_attachment_size'],
      plantuml_enabled: false,
      plantuml_url: nil,
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
      signin_enabled: Settings.gitlab['signin_enabled'],
      signup_enabled: Settings.gitlab['signup_enabled'],
      terminal_max_session_time: 0,
      two_factor_grace_period: 48,
      user_default_external: false,
      polling_interval_multiplier: 1,
      usage_ping_enabled: true
    }
  end

  def self.defaults
    defaults_ce
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

  def home_page_url_column_exist
    ActiveRecord::Base.connection.column_exists?(:application_settings, :home_page_url)
  end

  def sidekiq_throttling_column_exists?
    ActiveRecord::Base.connection.column_exists?(:application_settings, :sidekiq_throttling_enabled)
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

  # repository_storage is still required in the API. Remove in 9.0
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
