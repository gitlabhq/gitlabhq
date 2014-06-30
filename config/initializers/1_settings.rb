class Settings < Settingslogic
  source ENV.fetch('GITLAB_CONFIG') { "#{Rails.root}/config/gitlab.yml" }
  namespace Rails.env

  class << self
    def gitlab_on_standard_port?
      gitlab.port.to_i == (gitlab.https ? 443 : 80)
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
      custom_port = gitlab_on_standard_port? ? nil : ":#{gitlab.port}"
      [ gitlab.protocol,
        "://",
        gitlab.host,
        custom_port,
        gitlab.relative_url_root
      ].join('')
    end

    # check that values in `current` (string or integer) is a contant in `modul`.
    def verify_constant_array(modul, current, default)
      values = default || []
      if !current.nil?
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
      constant = modul.constants.find{ |name| modul.const_get(name) == current }
      value = constant.nil? ? default : modul.const_get(constant)
      if current.is_a? String
        value = modul.const_get(current.upcase) rescue default
      end
      value
    end
  end
end


# Default settings
Settings['ldap'] ||= Settingslogic.new({})
Settings.ldap['enabled'] = false if Settings.ldap['enabled'].nil?
Settings.ldap['allow_username_or_email_login'] = false if Settings.ldap['allow_username_or_email_login'].nil?


Settings['omniauth'] ||= Settingslogic.new({})
Settings.omniauth['enabled']      = false if Settings.omniauth['enabled'].nil?
Settings.omniauth['providers']  ||= []

Settings['issues_tracker']  ||= {}

#
# GitLab
#
Settings['gitlab'] ||= Settingslogic.new({})
Settings.gitlab['default_projects_limit'] ||= 10
Settings.gitlab['default_can_create_group'] = true if Settings.gitlab['default_can_create_group'].nil?
Settings.gitlab['default_theme'] = Gitlab::Theme::MARS if Settings.gitlab['default_theme'].nil?
Settings.gitlab['host']       ||= 'localhost'
Settings.gitlab['ssh_host']   ||= Settings.gitlab.host
Settings.gitlab['https']        = false if Settings.gitlab['https'].nil?
Settings.gitlab['port']       ||= Settings.gitlab.https ? 443 : 80
Settings.gitlab['relative_url_root'] ||= ENV['RAILS_RELATIVE_URL_ROOT'] || ''
Settings.gitlab['protocol']   ||= Settings.gitlab.https ? "https" : "http"
Settings.gitlab['email_from'] ||= "gitlab@#{Settings.gitlab.host}"
Settings.gitlab['url']        ||= Settings.send(:build_gitlab_url)
Settings.gitlab['user']       ||= 'git'
Settings.gitlab['user_home']  ||= begin
  Etc.getpwnam(Settings.gitlab['user']).dir
rescue ArgumentError # no user configured
  '/home/' + Settings.gitlab['user']
end
Settings.gitlab['signup_enabled'] ||= false
Settings.gitlab['signin_enabled'] ||= true if Settings.gitlab['signin_enabled'].nil?
Settings.gitlab['restricted_visibility_levels'] = Settings.send(:verify_constant_array, Gitlab::VisibilityLevel, Settings.gitlab['restricted_visibility_levels'], [])
Settings.gitlab['username_changing_enabled'] = true if Settings.gitlab['username_changing_enabled'].nil?
Settings.gitlab['issue_closing_pattern'] = '([Cc]lose[sd]|[Ff]ixe[sd]) #(\d+)' if Settings.gitlab['issue_closing_pattern'].nil?
Settings.gitlab['default_projects_features'] ||= {}
Settings.gitlab.default_projects_features['issues']         = true if Settings.gitlab.default_projects_features['issues'].nil?
Settings.gitlab.default_projects_features['merge_requests'] = true if Settings.gitlab.default_projects_features['merge_requests'].nil?
Settings.gitlab.default_projects_features['wiki']           = true if Settings.gitlab.default_projects_features['wiki'].nil?
Settings.gitlab.default_projects_features['snippets']       = false if Settings.gitlab.default_projects_features['snippets'].nil?
Settings.gitlab.default_projects_features['visibility_level']    = Settings.send(:verify_constant, Gitlab::VisibilityLevel, Settings.gitlab.default_projects_features['visibility_level'], Gitlab::VisibilityLevel::PRIVATE)
Settings.gitlab['repository_downloads_path'] = File.absolute_path(Settings.gitlab['repository_downloads_path'] || 'tmp/repositories', Rails.root)

#
# Gravatar
#
Settings['gravatar'] ||= Settingslogic.new({})
Settings.gravatar['enabled']      = true if Settings.gravatar['enabled'].nil?
Settings.gravatar['plain_url']  ||= 'http://www.gravatar.com/avatar/%{hash}?s=%{size}&d=identicon'
Settings.gravatar['ssl_url']    ||= 'https://secure.gravatar.com/avatar/%{hash}?s=%{size}&d=identicon'

#
# GitLab Shell
#
Settings['gitlab_shell'] ||= Settingslogic.new({})
Settings.gitlab_shell['path']         ||= Settings.gitlab['user_home'] + '/gitlab-shell/'
Settings.gitlab_shell['hooks_path']   ||= Settings.gitlab['user_home'] + '/gitlab-shell/hooks/'
Settings.gitlab_shell['receive_pack']   = true if Settings.gitlab_shell['receive_pack'].nil?
Settings.gitlab_shell['upload_pack']    = true if Settings.gitlab_shell['upload_pack'].nil?
Settings.gitlab_shell['repos_path']   ||= Settings.gitlab['user_home'] + '/repositories/'
Settings.gitlab_shell['ssh_host']     ||= Settings.gitlab.ssh_host
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

#
# Extra customization
#
Settings['extra'] ||= Settingslogic.new({})

#
# Testing settings
#
if Rails.env.test?
  Settings.gitlab['default_projects_limit']   = 42
  Settings.gitlab['default_can_create_group'] = true
  Settings.gitlab['default_can_create_team']  = false
end
