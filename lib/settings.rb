require_dependency 'gitlab'

class Settings < Settingslogic
  source ENV.fetch('GITLAB_CONFIG') { Gitlab.root.join('config/gitlab.yml') }
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

    def kerberos_protocol
      kerberos.https ? "https" : "http"
    end

    def kerberos_port
      kerberos.use_dedicated_port ? kerberos.port : gitlab.port
    end

    # Curl expects username/password for authentication. However when using GSS-Negotiate not credentials should be needed.
    # By inserting in the Kerberos dedicated URL ":@", we give to curl an empty username and password and GSS auth goes ahead
    # Known bug reported in http://sourceforge.net/p/curl/bugs/440/ and http://curl.haxx.se/docs/knownbugs.html
    def build_gitlab_kerberos_url
      [
        kerberos_protocol,
        "://:@",
        gitlab.host,
        ":#{kerberos_port}",
        gitlab.relative_url_root
      ].join('')
    end

    def alternative_gitlab_kerberos_url?
      kerberos.enabled && (build_gitlab_kerberos_url != build_gitlab_url)
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
