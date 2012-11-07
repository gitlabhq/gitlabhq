class Settings < Settingslogic
  source "#{Rails.root}/config/gitlab.yml"

  class << self
    def web_protocol
      self.web['protocol'] ||= web.https ? "https" : "http"
    end

    def web_host
      self.web['host'] ||= 'localhost'
    end

    def email_from
      self.email['from'] ||= ("notify@" + web_host)
    end

    def url
      self['url'] ||= build_url
    end

    def web_port
      if web.https
        web['port'] = 443
      else
        web['port'] ||= 80
      end.to_i
    end

    def web_custom_port?
      ![443, 80].include?(web_port)
    end

    def build_url
      if web_custom_port?
        custom_port = ":#{web_port}"
      else
        custom_port = nil
      end
      [
        web_protocol,
        "://",
        web_host,
        custom_port
      ].join('')
    end

    def ssh_port
      git_host['port'] || 22
    end

    def ssh_user
      git_host['git_user'] || 'git'
    end

    def ssh_host
      git_host['host'] || web_host || 'localhost'
    end

    def ssh_path
      if ssh_port != 22
        "ssh://#{ssh_user}@#{ssh_host}:#{ssh_port}/"
      else
        "#{ssh_user}@#{ssh_host}:"
      end
    end

    def git_base_path
      git_host['base_path'] || '/home/git/repositories/'
    end

    def git_hooks_path
      git_host['hooks_path'] || '/home/git/share/gitolite/hooks/'
    end

    def git_upload_pack
      if git_host['upload_pack'] != false
        true
      else
        false
      end
    end

    def git_receive_pack
      if git_host['receive_pack'] != false
        true
      else
        false
      end
    end

    def git_bin_path
      git['path'] || '/usr/bin/git'
    end

    def git_max_size
      git['git_max_size'] || 5242880 # 5.megabytes
    end

    def git_timeout
      git['git_timeout'] || 10
    end

    def gitolite_admin_uri
      git_host['admin_uri'] || 'git@localhost:gitolite-admin'
    end

    def gitolite_admin_key
      git_host['gitolite_admin_key'] || 'gitlab'
    end

    def default_projects_limit
      app['default_projects_limit'] || 10
    end

    def backup_path
      t = app['backup_path'] || "backups/"
      t = /^\//.match(t) ? t : Rails.root .join(t)
      t
    end

    def backup_keep_time
      app['backup_keep_time'] || 0
    end

    def omniauth_enabled?
      omniauth && omniauth['enabled']
    rescue Settingslogic::MissingSetting
      false
    end

    def omniauth_providers
      (omniauth_enabled? && omniauth['providers']) || {}
    end

    def disable_gravatar?
      app['disable_gravatar'] || false
    end
  end
end
