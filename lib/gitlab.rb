# frozen_string_literal: true

require 'pathname'

module Gitlab
  def self.root
    Pathname.new(File.expand_path('..', __dir__))
  end

  def self.version_info
    Gitlab::VersionInfo.parse(Gitlab::VERSION)
  end

  def self.pre_release?
    VERSION.include?('pre')
  end

  def self.config
    Settings
  end

  def self.revision
    @_revision ||= begin
      if File.exist?(root.join("REVISION"))
        File.read(root.join("REVISION")).strip.freeze
      else
        result = Gitlab::Popen.popen_with_detail(%W[#{config.git.bin_path} log --pretty=format:%h --abbrev=11 -n 1])

        if result.status.success?
          result.stdout.chomp.freeze
        else
          "Unknown"
        end
      end
    end
  end

  COM_URL = 'https://gitlab.com'
  APP_DIRS_PATTERN = %r{^/?(app|config|ee|lib|spec|\(\w*\))}.freeze
  SUBDOMAIN_REGEX = %r{\Ahttps://[a-z0-9]+\.gitlab\.com\z}.freeze
  VERSION = File.read(root.join("VERSION")).strip.freeze
  INSTALLATION_TYPE = File.read(root.join("INSTALLATION_TYPE")).strip.freeze
  HTTP_PROXY_ENV_VARS = %w(http_proxy https_proxy HTTP_PROXY HTTPS_PROXY).freeze

  def self.com?
    # Check `gl_subdomain?` as well to keep parity with gitlab.com
    Gitlab.config.gitlab.url == COM_URL || gl_subdomain?
  end

  def self.canary?
    Gitlab::Utils.to_boolean(ENV['CANARY'])
  end

  def self.com_and_canary?
    com? && canary?
  end

  def self.com_but_not_canary?
    com? && !canary?
  end

  def self.org?
    Gitlab.config.gitlab.url == 'https://dev.gitlab.org'
  end

  def self.gl_subdomain?
    SUBDOMAIN_REGEX === Gitlab.config.gitlab.url
  end

  def self.dev_env_org_or_com?
    dev_env_or_com? || org?
  end

  def self.dev_env_or_com?
    Rails.env.development? || com?
  end

  def self.ee?
    @is_ee ||=
      # We use this method when the Rails environment is not loaded. This
      # means that checking the presence of the License class could result in
      # this method returning `false`, even for an EE installation.
      #
      # The `FOSS_ONLY` is always `string` or `nil`
      # Thus the nil or empty string will result
      # in using default value: false
      #
      # The behavior needs to be synchronised with
      # config/helpers/is_ee_env.js
      root.join('ee/app/models/license.rb').exist? &&
        !%w[true 1].include?(ENV['FOSS_ONLY'].to_s)
  end

  def self.ee
    yield if ee?
  end

  def self.http_proxy_env?
    HTTP_PROXY_ENV_VARS.any? { |name| ENV[name] }
  end

  def self.process_name
    return 'sidekiq' if Sidekiq.server?
    return 'console' if defined?(Rails::Console)
    return 'test' if Rails.env.test?

    'web'
  end
end
