require_dependency 'settings'
require_dependency 'gitlab/popen'

module Gitlab
  def self.root
    Pathname.new(File.expand_path('..', __dir__))
  end

  def self.config
    Settings
  end

  COM_URL = 'https://gitlab.com'.freeze
  APP_DIRS_PATTERN = %r{^/?(app|config|ee|lib|spec|\(\w*\))}
  SUBDOMAIN_REGEX = %r{\Ahttps://[a-z0-9]+\.gitlab\.com\z}
  VERSION = File.read(root.join("VERSION")).strip.freeze
  REVISION = Gitlab::Popen.popen(%W(#{config.git.bin_path} log --pretty=format:%h -n 1)).first.chomp.freeze

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
    Rails.env.development? || org? || com?
  end
end
