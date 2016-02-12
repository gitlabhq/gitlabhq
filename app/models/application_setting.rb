# == Schema Information
#
# Table name: application_settings
#
#  id                                :integer          not null, primary key
#  default_projects_limit            :integer
#  signup_enabled                    :boolean
#  signin_enabled                    :boolean
#  gravatar_enabled                  :boolean
#  sign_in_text                      :text
#  created_at                        :datetime
#  updated_at                        :datetime
#  home_page_url                     :string(255)
#  default_branch_protection         :integer          default(2)
#  twitter_sharing_enabled           :boolean          default(TRUE)
#  restricted_visibility_levels      :text
#  version_check_enabled             :boolean          default(TRUE)
#  max_attachment_size               :integer          default(10), not null
#  default_project_visibility        :integer
#  default_snippet_visibility        :integer
#  restricted_signup_domains         :text
#  user_oauth_applications           :boolean          default(TRUE)
#  after_sign_out_path               :string(255)
#  session_expire_delay              :integer          default(10080), not null
#  import_sources                    :text
#  help_page_text                    :text
#  admin_notification_email          :string(255)
#  shared_runners_enabled            :boolean          default(TRUE), not null
#  max_artifacts_size                :integer          default(100), not null
#  runners_registration_token        :string
#  require_two_factor_authentication :boolean          default(FALSE)
#  two_factor_grace_period           :integer          default(48)
#  metrics_enabled                   :boolean          default(FALSE)
#  metrics_host                      :string           default("localhost")
#  metrics_username                  :string
#  metrics_password                  :string
#  metrics_pool_size                 :integer          default(16)
#  metrics_timeout                   :integer          default(10)
#  metrics_method_call_threshold     :integer          default(10)
#  recaptcha_enabled                 :boolean          default(FALSE)
#  recaptcha_site_key                :string
#  recaptcha_private_key             :string
#  metrics_port                      :integer          default(8089)
#  sentry_enabled                    :boolean          default(FALSE)
#  sentry_dsn                        :string
#  email_author_in_body              :boolean          default(FALSE)
#

class ApplicationSetting < ActiveRecord::Base
  include TokenAuthenticatable
  add_authentication_token_field :runners_registration_token

  CACHE_KEY = 'application_setting.last'

  serialize :restricted_visibility_levels
  serialize :import_sources
  serialize :restricted_signup_domains, Array
  attr_accessor :restricted_signup_domains_raw

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

  validates :max_attachment_size,
            presence: true,
            numericality: { only_integer: true, greater_than: 0 }

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

  before_save :ensure_runners_registration_token

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

  def self.create_from_defaults
    create(
      default_projects_limit: Settings.gitlab['default_projects_limit'],
      default_branch_protection: Settings.gitlab['default_branch_protection'],
      signup_enabled: Settings.gitlab['signup_enabled'],
      signin_enabled: Settings.gitlab['signin_enabled'],
      twitter_sharing_enabled: Settings.gitlab['twitter_sharing_enabled'],
      gravatar_enabled: Settings.gravatar['enabled'],
      sign_in_text: Settings.extra['sign_in_text'],
      restricted_visibility_levels: Settings.gitlab['restricted_visibility_levels'],
      max_attachment_size: Settings.gitlab['max_attachment_size'],
      session_expire_delay: Settings.gitlab['session_expire_delay'],
      default_project_visibility: Settings.gitlab.default_projects_features['visibility_level'],
      default_snippet_visibility: Settings.gitlab.default_projects_features['visibility_level'],
      restricted_signup_domains: Settings.gitlab['restricted_signup_domains'],
      import_sources: ['github','bitbucket','gitlab','gitorious','google_code','fogbugz','git'],
      shared_runners_enabled: Settings.gitlab_ci['shared_runners_enabled'],
      max_artifacts_size: Settings.artifacts['max_size'],
      require_two_factor_authentication: false,
      two_factor_grace_period: 48,
      recaptcha_enabled: false,
      akismet_enabled: false
    )
  end

  def home_page_url_column_exist
    ActiveRecord::Base.connection.column_exists?(:application_settings, :home_page_url)
  end

  def restricted_signup_domains_raw
    self.restricted_signup_domains.join("\n") unless self.restricted_signup_domains.nil?
  end

  def restricted_signup_domains_raw=(values)
    self.restricted_signup_domains = []
    self.restricted_signup_domains = values.split(
      /\s*[,;]\s*     # comma or semicolon, optionally surrounded by whitespace
      |               # or
      \s              # any whitespace character
      |               # or
      [\r\n]          # any number of newline characters
      /x)
    self.restricted_signup_domains.reject! { |d| d.empty? }
  end

  def runners_registration_token
    ensure_runners_registration_token!
  end
end
