require_dependency 'gitlab/git'

module Gitlab
  SUBDOMAIN_REGEX = %r{\Ahttps://[a-z0-9]+\.gitlab\.com\z}
  COM_URL = 'https://gitlab.com'.freeze
  SUBSCRIPTIONS_URL = 'https://customers.gitlab.com'.freeze

  def self.com?
    # Check `gl_subdomain?` as well to keep parity with gitlab.com
    Gitlab.config.gitlab.url == COM_URL || gl_subdomain?
  end

  def self.gl_subdomain?
    SUBDOMAIN_REGEX === Gitlab.config.gitlab.url
  end
end
