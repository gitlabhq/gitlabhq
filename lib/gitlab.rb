require_dependency 'gitlab/git'

module Gitlab
  SUBDOMAIN_REGEX = %r{\Ahttps://[a-z0-9]+\.gitlab\.com\z}

  def self.com?
    # Check `gl_subdomain?` as well to keep parity with gitlab.com
    Gitlab.config.gitlab.url == 'https://gitlab.com' || gl_subdomain?
  end

  def self.gl_subdomain?
    SUBDOMAIN_REGEX === Gitlab.config.gitlab.url
  end
end
