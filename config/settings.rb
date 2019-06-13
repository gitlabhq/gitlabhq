require 'settingslogic'

# We can not use `Rails.root` here, as this file might be loaded without the
# full Rails environment being loaded. We can not use `require_relative` either,
# as Rails uses `load` for `require_dependency` (used when loading the Rails
# environment). This could then lead to this file being loaded twice.
require_dependency File.expand_path('../lib/gitlab', __dir__)

class Settings < Settingslogic
  source ENV.fetch('GITLAB_CONFIG') { Pathname.new(File.expand_path('..', __dir__)).join('config/gitlab.yml') }
  namespace ENV.fetch('GITLAB_ENV') { Rails.env }

  class << self
    def gitlab_on_standard_port?
      on_standard_port?(gitlab)
    end

    def host_without_www(url)
      host(url).sub('www.', '')
    end

    def build_gitlab_ci_url
      custom_port =
        if on_standard_port?(gitlab)
          nil
        else
          ":#{gitlab.port}"
        end

      [
        gitlab.protocol,
        "://",
        gitlab.host,
        custom_port,
        gitlab.relative_url_root
      ].join('')
    end

    def build_pages_url
      base_url(pages).join('')
    end

    def build_gitlab_shell_ssh_path_prefix
      user_host = "#{gitlab_shell.ssh_user}@#{gitlab_shell.ssh_host}"

      if gitlab_shell.ssh_port != 22
        "ssh://#{user_host}:#{gitlab_shell.ssh_port}/"
      else
        if gitlab_shell.ssh_host.include? ':'
          "[#{user_host}]:"
        else
          "#{user_host}:"
        end
      end
    end

    def build_base_gitlab_url
      base_url(gitlab).join('')
    end

    def build_gitlab_url
      (base_url(gitlab) + [gitlab.relative_url_root]).join('')
    end

    # check that values in `current` (string or integer) is a contant in `modul`.
    def verify_constant_array(modul, current, default)
      values = default || []
      unless current.nil?
        values = []
        current.each do |constant|
          values.push(verify_constant(modul, constant, nil))
        end
        values.delete_if { |value| value.nil? }
      end

      values
    end

    # check that `current` (string or integer) is a contant in `modul`.
    def verify_constant(modul, current, default)
      constant = modul.constants.find { |name| modul.const_get(name) == current }
      value = constant.nil? ? default : modul.const_get(constant)
      if current.is_a? String
        value = modul.const_get(current.upcase) rescue default
      end

      value
    end

    def absolute(path)
      File.expand_path(path, Rails.root)
    end

    # Ruby 2.4+ requires passing in the exact required length for OpenSSL keys
    # (https://github.com/ruby/ruby/commit/ce635262f53b760284d56bb1027baebaaec175d1).
    # Previous versions quietly truncated the input.
    #
    # Use this when using :per_attribute_iv mode for attr_encrypted.
    # We have to truncate the string to 32 bytes for a 256-bit cipher.
    def attr_encrypted_db_key_base_truncated
      Gitlab::Application.secrets.db_key_base[0..31]
    end

    def attr_encrypted_db_key_base_32
      Gitlab::Utils.ensure_utf8_size(attr_encrypted_db_key_base, bytes: 32.bytes)
    end

    def attr_encrypted_db_key_base_12
      Gitlab::Utils.ensure_utf8_size(attr_encrypted_db_key_base, bytes: 12.bytes)
    end

    # This should be used for :per_attribute_salt_and_iv mode. There is no
    # need to truncate the key because the encryptor will use the salt to
    # generate a hash of the password:
    # https://github.com/attr-encrypted/encryptor/blob/c3a62c4a9e74686dd95e0548f9dc2a361fdc95d1/lib/encryptor.rb#L77
    def attr_encrypted_db_key_base
      Gitlab::Application.secrets.db_key_base
    end

    private

    def base_url(config)
      custom_port = on_standard_port?(config) ? nil : ":#{config.port}"

      [
        config.protocol,
        "://",
        config.host,
        custom_port
      ]
    end

    def on_standard_port?(config)
      config.port.to_i == (config.https ? 443 : 80)
    end

    # Extract the host part of the given +url+.
    def host(url)
      url = url.downcase
      url = "http://#{url}" unless url.start_with?('http')

      # Get rid of the path so that we don't even have to encode it
      url_without_path = url.sub(%r{(https?://[^/]+)/?.*}, '\1')

      URI.parse(url_without_path).host
    end

    # Runs every minute in a random ten-minute period on Sundays, to balance the
    # load on the server receiving these pings. The usage ping is safe to run
    # multiple times because of a 24 hour exclusive lock.
    def cron_for_usage_ping
      hour = rand(24)
      minute = rand(6)

      "#{minute}0-#{minute}9 #{hour} * * 0"
    end
  end
end
