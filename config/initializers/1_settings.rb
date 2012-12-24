class Settings < Settingslogic
  source "#{Rails.root}/config/gitlab.yml"

  class << self
    def gitlab_on_non_standard_port?
      ![443, 80].include?(gitlab.port.to_i)
    end

    private

    def build_gitolite_ssh_path_prefix
      if gitolite.ssh_port != 22
        "ssh://#{gitolite.ssh_user}@#{gitolite.ssh_host}:#{gitolite.ssh_port}/"
      else
        "#{gitolite.ssh_user}@#{gitolite.ssh_host}:"
      end
    end

    def build_gitlab_url
      if gitlab_on_non_standard_port?
        custom_port = ":#{gitlab.port}"
      else
        custom_port = nil
      end
      [ gitlab.protocol,
        "://",
        gitlab.host,
        custom_port
      ].join('')
    end
  end
end


# Default settings
Settings['ldap'] ||= Settingslogic.new({})
Settings.ldap['enabled'] ||= false

Settings['omniauth'] ||= Settingslogic.new({})
Settings.omniauth['enabled']    ||= false
Settings.omniauth['providers']  ||= []

Settings['gitlab'] ||= Settingslogic.new({})
Settings.gitlab['default_projects_limit'] ||=  10
Settings.gitlab['host']       ||= 'localhost'
Settings.gitlab['https']      ||= false
Settings.gitlab['port']       ||= Settings.gitlab.https ? 443 : 80
Settings.gitlab['protocol']   ||= Settings.gitlab.https ? "https" : "http"
Settings.gitlab['email_from'] ||= "gitlab@#{Settings.gitlab.host}"
Settings.gitlab['url']        ||= Settings.send(:build_gitlab_url)

Settings['gravatar'] ||= Settingslogic.new({})
Settings.gravatar['enabled']    ||= true
Settings.gravatar['plain_url']  ||= 'http://www.gravatar.com/avatar/%{hash}?s=%{size}&d=mm'
Settings.gravatar['ssl_url']    ||= 'https://secure.gravatar.com/avatar/%{hash}?s=%{size}&d=mm'

Settings['gitolite'] ||= Settingslogic.new({})
Settings.gitolite['admin_key']    ||= 'gitlab'
Settings.gitolite['admin_uri']    ||= 'git@localhost:gitolite-admin'
Settings.gitolite['config_file']  ||= 'gitolite.conf'
Settings.gitolite['hooks_path']   ||= '/home/git/share/gitolite/hooks/'
Settings.gitolite['receive_pack'] ||= (Settings.gitolite['receive_pack'] != false)
Settings.gitolite['repos_path']   ||= '/home/git/repositories/'
Settings.gitolite['upload_pack']  ||= (Settings.gitolite['upload_pack'] != false)
Settings.gitolite['ssh_host']     ||= (Settings.gitlab.host || 'localhost')
Settings.gitolite['ssh_port']     ||= 22
Settings.gitolite['ssh_user']     ||= 'git'
Settings.gitolite['ssh_path_prefix'] ||= Settings.send(:build_gitolite_ssh_path_prefix)

Settings['backup'] ||= Settingslogic.new({})
Settings.backup['keep_time']  ||= 0
Settings.backup['path']         = File.expand_path(Settings.backup['path'] || "tmp/backups/", Rails.root)

Settings['git'] ||= Settingslogic.new({})
Settings.git['max_size']  ||= 5242880 # 5.megabytes
Settings.git['bin_path']  ||= '/usr/bin/git'
Settings.git['timeout']   ||= Settings.git_timeout : 10
