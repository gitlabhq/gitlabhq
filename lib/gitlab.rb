require_dependency 'gitlab/git'

module Gitlab
  COM_URL = 'https://gitlab.com'.freeze
  APP_DIRS_PATTERN = %r{^/?(app|config|ee|lib|spec|\(\w*\))}
  SUBDOMAIN_REGEX = %r{\Ahttps://[a-z0-9]+\.gitlab\.com\z}
  SUBSCRIPTIONS_URL = 'https://customers.gitlab.com'.freeze
  SUBSCRIPTIONS_PLANS_URL = "#{SUBSCRIPTIONS_URL}/plans".freeze

  def self.root
    Pathname.new(File.expand_path('..', __dir__))
  end

  def self.com?
    # Check `gl_subdomain?` as well to keep parity with gitlab.com
    Gitlab.config.gitlab.url == COM_URL || gl_subdomain?
  end

  def self.org?
    Gitlab.config.gitlab.url == 'https://dev.gitlab.org'
  end

  def self.gl_subdomain?
    SUBDOMAIN_REGEX === Gitlab.config.gitlab.url
  end

  def self.dev_env_or_com?
    Rails.env.test? || Rails.env.development? || org? || com?
  end
end
