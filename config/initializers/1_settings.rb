class Settings < Settingslogic
  source "#{Rails.root}/config/gitlab.yml"
  namespace Rails.env

  class << self
    def gitlab_on_non_standard_port?
      ![443, 80].include?(gitlab.port.to_i)
    end

    private

    def build_gitlab_shell_ssh_path_prefix
      if gitlab_shell.ssh_port != 22
        "ssh://#{gitlab_shell.ssh_user}@#{gitlab_shell.ssh_host}:#{gitlab_shell.ssh_port}/"
      else
        "#{gitlab_shell.ssh_user}@#{gitlab_shell.ssh_host}:"
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
        custom_port,
        gitlab.relative_url_root
      ].join('')
    end
  end
end


# Default settings
Settings['ldap'] ||= Settingslogic.new({})
Settings.ldap['enabled'] = false if Settings.ldap['enabled'].nil?

Settings['omniauth'] ||= Settingslogic.new({})
Settings.omniauth['enabled']      = false if Settings.omniauth['enabled'].nil?
Settings.omniauth['providers']  ||= []

Settings['issues_tracker']  ||= {}

#
# GitLab
#
Settings['gitlab'] ||= Settingslogic.new({})
Settings.gitlab['default_projects_limit'] ||=  10
Settings.gitlab['host']       ||= 'localhost'
Settings.gitlab['https']        = false if Settings.gitlab['https'].nil?
Settings.gitlab['port']       ||= Settings.gitlab.https ? 443 : 80
Settings.gitlab['relative_url_root'] ||= ''
Settings.gitlab['protocol']   ||= Settings.gitlab.https ? "https" : "http"
Settings.gitlab['email_from'] ||= "gitlab@#{Settings.gitlab.host}"
Settings.gitlab['support_email']  ||= Settings.gitlab.email_from
Settings.gitlab['url']        ||= Settings.send(:build_gitlab_url)
Settings.gitlab['user']       ||= 'git'
Settings.gitlab['signup_enabled'] ||= false
Settings.gitlab['username_changing_enabled'] = true if Settings.gitlab['username_changing_enabled'].nil?

#
# Gravatar
#
Settings['gravatar'] ||= Settingslogic.new({})
Settings.gravatar['enabled']      = true if Settings.gravatar['enabled'].nil?
Settings.gravatar['plain_url']  ||= 'http://www.gravatar.com/avatar/%{hash}?s=%{size}&d=mm'
Settings.gravatar['ssl_url']    ||= 'https://secure.gravatar.com/avatar/%{hash}?s=%{size}&d=mm'

#
# GitLab Shell
#
Settings['gitlab_shell'] ||= Settingslogic.new({})
Settings.gitlab_shell['hooks_path']   ||= '/home/git/gitlab-shell/hooks/'
Settings.gitlab_shell['receive_pack']   = true if Settings.gitlab_shell['receive_pack'].nil?
Settings.gitlab_shell['upload_pack']    = true if Settings.gitlab_shell['upload_pack'].nil?
Settings.gitlab_shell['repos_path']   ||= '/home/git/repositories/'
Settings.gitlab_shell['ssh_host']     ||= (Settings.gitlab.host || 'localhost')
Settings.gitlab_shell['ssh_port']     ||= 22
Settings.gitlab_shell['ssh_user']     ||= Settings.gitlab.user
Settings.gitlab_shell['owner_group']  ||= Settings.gitlab.user
Settings.gitlab_shell['ssh_path_prefix'] ||= Settings.send(:build_gitlab_shell_ssh_path_prefix)

#
# Backup
#
Settings['backup'] ||= Settingslogic.new({})
Settings.backup['keep_time']  ||= 0
Settings.backup['path']         = File.expand_path(Settings.backup['path'] || "tmp/backups/", Rails.root)

#
# Git
#
Settings['git'] ||= Settingslogic.new({})
Settings.git['max_size']  ||= 5242880 # 5.megabytes
Settings.git['bin_path']  ||= '/usr/bin/git'
Settings.git['timeout']   ||= 10

Settings['satellites'] ||= Settingslogic.new({})
Settings.satellites['path'] = File.expand_path(Settings.satellites['path'] || "tmp/repo_satellites/", Rails.root)
