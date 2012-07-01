class Settings < Settingslogic
  source "#{Rails.root}/config/gitlab.yml"

  class << self
    def web_protocol
      self.web['protocol'] ||= web.https ? "https://" : "http://"
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

    def build_url
      raw_url = self.web_protocol
      raw_url << web.host
      raw_url << ":#{web.port}" if web.port.to_i != 80
      raw_url
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
      git['admin_uri'] || 'git@localhost:gitolite-admin'
    end

    def default_projects_limit
      app['default_projects_limit'] || 10
    end
  end
end
