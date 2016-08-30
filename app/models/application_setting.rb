class ApplicationSetting < ActiveRecord::Base
  include TokenAuthenticatable
  add_authentication_token_field :runners_registration_token
  add_authentication_token_field :health_check_access_token

  CACHE_KEY = 'application_setting.last'
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

  attr_accessor :domain_whitelist_raw, :domain_blacklist_raw

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

  validates :koding_url,
            presence: true,
            if: :koding_enabled

  validates :max_attachment_size,
            presence: true,
            numericality: { only_integer: true, greater_than: 0 }

  validates :container_registry_token_expire_delay,
            presence: true,
            numericality: { only_integer: true, greater_than: 0 }

  validates :elasticsearch_host,
            presence: { message: "can't be blank when indexing is enabled" },
            if: :elasticsearch_indexing?

  validates :elasticsearch_port,
            presence: { message: "can't be blank when indexing is enabled" },
            if: :elasticsearch_indexing?

  validates :repository_storage,
    presence: true,
    inclusion: { in: ->(_object) { Gitlab.config.repositories.storages.keys } }

  validates :enabled_git_access_protocol,
            inclusion: { in: %w(ssh http), allow_blank: true, allow_nil: true }

  validates :domain_blacklist,
            presence: { message: 'Domain blacklist cannot be empty if Blacklist is enabled.' },
            if: :domain_blacklist_enabled?

  validates_each :restricted_visibility_levels do |record, attr, value|
    unless value.nil?
      value.each do |level|
        unless Gitlab::VisibilityLevel.options.has_value?(level)
          record.errors.add(attr, "'#{level}' is not a valid visibility level")
        end
      end
    end
  end

  validates_each :import_sources do |record, attr, value|
    unless value.nil?
      value.each do |source|
        unless Gitlab::ImportSources.options.has_value?(source)
          record.errors.add(attr, "'#{source}' is not a import source")
        end
      end
    end
  end

  validates_each :disabled_oauth_sign_in_sources do |record, attr, value|
    unless value.nil?
      value.each do |source|
        unless Devise.omniauth_providers.include?(source.to_sym)
          record.errors.add(attr, "'#{source}' is not an OAuth sign-in source")
        end
      end
    end
  end

  before_save :ensure_runners_registration_token
  before_save :ensure_health_check_access_token

  after_commit do
    Rails.cache.write(CACHE_KEY, self)
  end

  def self.current
    Rails.cache.fetch(CACHE_KEY) do
      ApplicationSetting.last
    end
  end

  def self.expire
    Rails.cache.delete(CACHE_KEY)
  end

  def self.cached
    Rails.cache.fetch(CACHE_KEY)
  end

  def self.create_from_defaults
    create(
      default_projects_limit: Settings.gitlab['default_projects_limit'],
      default_branch_protection: Settings.gitlab['default_branch_protection'],
      signup_enabled: Settings.gitlab['signup_enabled'],
      signin_enabled: Settings.gitlab['signin_enabled'],
      gravatar_enabled: Settings.gravatar['enabled'],
      sign_in_text: nil,
      after_sign_up_text: nil,
      help_page_text: nil,
      shared_runners_text: nil,
      restricted_visibility_levels: Settings.gitlab['restricted_visibility_levels'],
      max_attachment_size: Settings.gitlab['max_attachment_size'],
      session_expire_delay: Settings.gitlab['session_expire_delay'],
      default_project_visibility: Settings.gitlab.default_projects_features['visibility_level'],
      default_snippet_visibility: Settings.gitlab.default_projects_features['visibility_level'],
      domain_whitelist: Settings.gitlab['domain_whitelist'],
      import_sources: %w[github bitbucket gitlab google_code fogbugz git gitlab_project],
      shared_runners_enabled: Settings.gitlab_ci['shared_runners_enabled'],
      max_artifacts_size: Settings.artifacts['max_size'],
      require_two_factor_authentication: false,
      two_factor_grace_period: 48,
      recaptcha_enabled: false,
      akismet_enabled: false,
      koding_enabled: false,
      koding_url: nil,
      repository_checks_enabled: true,
      disabled_oauth_sign_in_sources: [],
      send_user_confirmation_email: false,
      container_registry_token_expire_delay: 5,
      elasticsearch_host: ENV['ELASTIC_HOST'] || 'localhost',
      elasticsearch_port: ENV['ELASTIC_PORT'] || '9200',
      usage_ping_enabled: true,
      repository_storage: 'default',
      user_default_external: false,
    )
  end

  def elasticsearch_host
    read_attribute(:elasticsearch_host).split(',').map(&:strip)
  end

  def home_page_url_column_exist
    ActiveRecord::Base.connection.column_exists?(:application_settings, :home_page_url)
  end

  def domain_whitelist_raw
    self.domain_whitelist.join("\n") unless self.domain_whitelist.nil?
  end

  def domain_blacklist_raw
    self.domain_blacklist.join("\n") unless self.domain_blacklist.nil?
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

  def runners_registration_token
    ensure_runners_registration_token!
  end

  def health_check_access_token
    ensure_health_check_access_token!
  end
end
