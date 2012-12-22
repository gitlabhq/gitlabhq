class Settings < Settingslogic
  source "#{Rails.root}/config/gitlab.yml"

  class << self
    # FIXME: Deprecated: remove for 4.1
    def web_protocol
      ActiveSupport::Deprecation.warn("Settings.web_protocol is deprecated and will be removed from GitLab 4.1", caller)
      gitlab.protocol
    rescue Settingslogic::MissingSetting
      self.web['protocol'] ||= web.https ? "https" : "http"
    end

    # FIXME: Deprecated: remove for 4.1
    def web_host
      ActiveSupport::Deprecation.warn("Settings.web_host is deprecated and will be removed from GitLab 4.1", caller)
      gitlab.host
    rescue Settingslogic::MissingSetting
      self.web['host'] ||= 'localhost'
    end

    # FIXME: Deprecated: remove for 4.1
    def email_from
      ActiveSupport::Deprecation.warn("Settings.email_from is deprecated and will be removed from GitLab 4.1", caller)
      gitlab.email_from
    rescue Settingslogic::MissingSetting
      self.email['from'] ||= ("notify@" + web_host)
    end

    # FIXME: Deprecated: remove for 4.1
    def url
      ActiveSupport::Deprecation.warn("Settings.url is deprecated and will be removed from GitLab 4.1", caller)
      gitlab.url
    rescue Settingslogic::MissingSetting
      self['url'] ||= build_url
    end

    # FIXME: Deprecated: remove for 4.1
    def web_port
      ActiveSupport::Deprecation.warn("Settings.web_port is deprecated and will be removed from GitLab 4.1", caller)
      gitlab.port.to_i
    rescue Settingslogic::MissingSetting
      if web.https
        web['port'] = 443
      else
        web['port'] ||= 80
      end.to_i
    end

    # FIXME: Deprecated: remove for 4.1
    def web_custom_port?
      ActiveSupport::Deprecation.warn("Settings.web_custom_port? is deprecated and will be removed from GitLab 4.1", caller)
      gitlab_on_non_standard_port?
    rescue Settingslogic::MissingSetting
      ![443, 80].include?(web_port)
    end

    # FIXME: Deprecated: remove for 4.1
    def build_url
      ActiveSupport::Deprecation.warn("Settings.build_url is deprecated and will be removed from GitLab 4.1", caller)
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

    # FIXME: Deprecated: remove for 4.1
    def ssh_port
      ActiveSupport::Deprecation.warn("Settings.ssh_port is deprecated and will be removed from GitLab 4.1", caller)
      gitolite.ssh_port
    rescue Settingslogic::MissingSetting
      git_host['port'] || 22
    end

    # FIXME: Deprecated: remove for 4.1
    def ssh_user
      ActiveSupport::Deprecation.warn("Settings.ssh_user is deprecated and will be removed from GitLab 4.1", caller)
      gitolite.ssh_user
    rescue Settingslogic::MissingSetting
      git_host['git_user'] || 'git'
    end

    # FIXME: Deprecated: remove for 4.1
    def ssh_host
      ActiveSupport::Deprecation.warn("Settings.ssh_host is deprecated and will be removed from GitLab 4.1", caller)
      gitolite.ssh_host
    rescue Settingslogic::MissingSetting
      git_host['host'] || web_host || 'localhost'
    end

    # FIXME: Deprecated: remove for 4.1
    def ssh_path
      ActiveSupport::Deprecation.warn("Settings.ssh_path is deprecated and will be removed from GitLab 4.1", caller)
      gitolite.ssh_path_prefix
    rescue Settingslogic::MissingSetting
      if ssh_port != 22
        "ssh://#{ssh_user}@#{ssh_host}:#{ssh_port}/"
      else
        "#{ssh_user}@#{ssh_host}:"
      end
    end

    # FIXME: Deprecated: remove for 4.1
    def git_base_path
      ActiveSupport::Deprecation.warn("Settings.git_base_path is deprecated and will be removed from GitLab 4.1", caller)
      gitolite.repos_path
    rescue Settingslogic::MissingSetting
      git_host['base_path'] || '/home/git/repositories/'
    end

    # FIXME: Deprecated: remove for 4.1
    def git_hooks_path
      ActiveSupport::Deprecation.warn("Settings.git_hooks_path is deprecated and will be removed from GitLab 4.1", caller)
      gitolite.hooks_path
    rescue Settingslogic::MissingSetting
      git_host['hooks_path'] || '/home/git/share/gitolite/hooks/'
    end

    # FIXME: Deprecated: remove for 4.1
    def git_upload_pack
      ActiveSupport::Deprecation.warn("Settings.git_upload_pack is deprecated and will be removed from GitLab 4.1", caller)
      gitolite.upload_pack
    rescue Settingslogic::MissingSetting
      if git_host['upload_pack'] != false
        true
      else
        false
      end
    end

    # FIXME: Deprecated: remove for 4.1
    def git_receive_pack
      ActiveSupport::Deprecation.warn("Settings.git_receive_pack is deprecated and will be removed from GitLab 4.1", caller)
      gitolite.receive_pack
    rescue Settingslogic::MissingSetting
      if git_host['receive_pack'] != false
        true
      else
        false
      end
    end

    # FIXME: Deprecated: remove for 4.1
    def git_bin_path
      ActiveSupport::Deprecation.warn("Settings.git_bin_path is deprecated and will be removed from GitLab 4.1", caller)
      git.bin_path
    rescue Settingslogic::MissingSetting
      git['path'] || '/usr/bin/git'
    end

    # FIXME: Deprecated: remove for 4.1
    def git_max_size
      ActiveSupport::Deprecation.warn("Settings.git_max_size is deprecated and will be removed from GitLab 4.1", caller)
      git.max_size
    rescue Settingslogic::MissingSetting
      git['git_max_size'] || 5242880 # 5.megabytes
    end

    # FIXME: Deprecated: remove for 4.1
    def git_timeout
      ActiveSupport::Deprecation.warn("Settings.git_timeout is deprecated and will be removed from GitLab 4.1", caller)
      git.timeout
    rescue Settingslogic::MissingSetting
      git['git_timeout'] || 10
    end

    # FIXME: Deprecated: remove for 4.1
    def gitolite_admin_uri
      ActiveSupport::Deprecation.warn("Settings.gitolite_admin_uri is deprecated and will be removed from GitLab 4.1", caller)
      gitolite.admin_uri
    rescue Settingslogic::MissingSetting
      git_host['admin_uri'] || 'git@localhost:gitolite-admin'
    end

    # FIXME: Deprecated: remove for 4.1
    def gitolite_config_file
      ActiveSupport::Deprecation.warn("Settings.gitolite_config_file is deprecated and will be removed from GitLab 4.1", caller)
      gitolite.config_file
    rescue Settingslogic::MissingSetting
      git_host['config_file'] || 'gitolite.conf'
    end

    # FIXME: Deprecated: remove for 4.1
    def gitolite_admin_key
      ActiveSupport::Deprecation.warn("Settings.gitolite_admin_key is deprecated and will be removed from GitLab 4.1", caller)
      gitolite.admin_key
    rescue Settingslogic::MissingSetting
      git_host['gitolite_admin_key'] || 'gitlab'
    end

    # FIXME: Deprecated: remove for 4.1
    def default_projects_limit
      ActiveSupport::Deprecation.warn("Settings.default_projects_limit is deprecated and will be removed from GitLab 4.1", caller)
      gitlab.default_projects_limit
    rescue Settingslogic::MissingSetting
      app['default_projects_limit'] || 10
    end

    # FIXME: Deprecated: remove for 4.1
    def backup_path
      ActiveSupport::Deprecation.warn("Settings.backup_path is deprecated and will be removed from GitLab 4.1", caller)
      backup.path
    rescue Settingslogic::MissingSetting
      File.expand_path(app['backup_path'] || "backups/", Rails.root)
    end

    # FIXME: Deprecated: remove for 4.1
    def backup_keep_time
      ActiveSupport::Deprecation.warn("Settings.backup_keep_time is deprecated and will be removed from GitLab 4.1", caller)
      backup.keep_time
    rescue Settingslogic::MissingSetting
      app['backup_keep_time'] || 0
    end

    # FIXME: Deprecated: remove for 4.1
    def ldap_enabled?
      ActiveSupport::Deprecation.warn("Settings.ldap_enabled? is deprecated and will be removed from GitLab 4.1", caller)
      ldap.enabled
    rescue Settingslogic::MissingSetting
      false
    end

    # FIXME: Deprecated: remove for 4.1
    def omniauth_enabled?
      ActiveSupport::Deprecation.warn("Settings.omniauth_enabled? is deprecated and will be removed from GitLab 4.1", caller)
      omniauth.enabled
    rescue Settingslogic::MissingSetting
      false
    end

    # FIXME: Deprecated: remove for 4.1
    def omniauth_providers
      ActiveSupport::Deprecation.warn("Settings.omniauth_providers is deprecated and will be removed from GitLab 4.1", caller)
      omniauth.providers
    rescue Settingslogic::MissingSetting
      []
    end

    # FIXME: Deprecated: remove for 4.1
    def disable_gravatar?
      ActiveSupport::Deprecation.warn("Settings.disable_gravatar? is deprecated and will be removed from GitLab 4.1", caller)
      !gravatar.enabled
    rescue Settingslogic::MissingSetting
      app['disable_gravatar'] || false
    end

    # FIXME: Deprecated: remove for 4.1
    def gravatar_url
      ActiveSupport::Deprecation.warn("Settings.gravatar_url is deprecated and will be removed from GitLab 4.1", caller)
      gravatar.plain_url
    rescue Settingslogic::MissingSetting
      app['gravatar_url'] || 'http://www.gravatar.com/avatar/%{hash}?s=%{size}&d=mm'
    end

    # FIXME: Deprecated: remove for 4.1
    def gravatar_ssl_url
      ActiveSupport::Deprecation.warn("Settings.gravatar_ssl_url is deprecated and will be removed from GitLab 4.1", caller)
      gravatar.ssl_url
    rescue Settingslogic::MissingSetting
      app['gravatar_ssl_url'] || 'https://secure.gravatar.com/avatar/%{hash}?s=%{size}&d=mm'
    end



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

# FIXME: Deprecated: remove for 4.1
# all Settings.web ...
# all Settings.app ...
# all Settings.email ...
# all Settings.git_host ...
Settings['pre_40_config'] ||= Settings['web'].present?

Settings['ldap'] ||= Settingslogic.new({})
Settings.ldap['enabled'] ||= false

Settings['omniauth'] ||= Settingslogic.new({})
Settings.omniauth['enabled']    ||= false
Settings.omniauth['providers']  ||= []

Settings['gitlab'] ||= Settingslogic.new({})
Settings.gitlab['default_projects_limit'] ||= Settings.pre_40_config ? Settings.default_projects_limit : 10
Settings.gitlab['host']       ||= Settings.pre_40_config ? Settings.web_host : 'localhost'
Settings.gitlab['https']      ||= Settings.pre_40_config ? Settings.web.https : false
Settings.gitlab['port']       ||= Settings.gitlab.https ? 443 : 80
Settings.gitlab['protocol']   ||= Settings.gitlab.https ? "https" : "http"
Settings.gitlab['email_from'] ||= Settings.pre_40_config ? Settings.email_from : "gitlab@#{Settings.gitlab.host}"
Settings.gitlab['url']        ||= Settings.pre_40_config ? Settings.url : Settings.send(:build_gitlab_url)

Settings['gravatar'] ||= Settingslogic.new({})
Settings.gravatar['enabled']    ||= Settings.pre_40_config ? !Settings.disable_gravatar? : true
Settings.gravatar['plain_url']  ||= Settings.pre_40_config ? Settings.gravatar_url      : 'http://www.gravatar.com/avatar/%{hash}?s=%{size}&d=mm'
Settings.gravatar['ssl_url']    ||= Settings.pre_40_config ? Settings.gravatar_ssl_url  : 'https://secure.gravatar.com/avatar/%{hash}?s=%{size}&d=mm'

Settings['gitolite'] ||= Settingslogic.new({})
Settings.gitolite['admin_key']    ||= Settings.pre_40_config ? Settings.gitolite_admin_key : 'gitlab'
Settings.gitolite['admin_uri']    ||= Settings.pre_40_config ? Settings.gitolite_admin_uri : 'git@localhost:gitolite-admin'
Settings.gitolite['config_file']  ||= Settings.pre_40_config ? Settings.gitolite_config_file : 'gitolite.conf'
Settings.gitolite['hooks_path']   ||= Settings.pre_40_config ? Settings.git_hooks_path : '/home/git/share/gitolite/hooks/'
Settings.gitolite['receive_pack'] ||= Settings.pre_40_config ? Settings.git_receive_pack : (Settings.gitolite['receive_pack'] != false)
Settings.gitolite['repos_path']   ||= Settings.pre_40_config ? Settings.git_base_path : '/home/git/repositories/'
Settings.gitolite['upload_pack']  ||= Settings.pre_40_config ? Settings.git_upload_pack : (Settings.gitolite['upload_pack'] != false)
Settings.gitolite['ssh_host']     ||= Settings.pre_40_config ? Settings.ssh_host : (Settings.gitlab.host || 'localhost')
Settings.gitolite['ssh_port']     ||= Settings.pre_40_config ? Settings.ssh_port : 22
Settings.gitolite['ssh_user']     ||= Settings.pre_40_config ? Settings.ssh_user : 'git'
Settings.gitolite['ssh_path_prefix'] ||= Settings.pre_40_config ? Settings.ssh_path : Settings.send(:build_gitolite_ssh_path_prefix)

Settings['backup'] ||= Settingslogic.new({})
Settings.backup['keep_time']  ||= Settings.pre_40_config ? Settings.backup_keep_time : 0
Settings.backup['path']         = Settings.pre_40_config ? Settings.backup_path : File.expand_path(Settings.backup['path'] || "tmp/backups/", Rails.root)

Settings['git'] ||= Settingslogic.new({})
Settings.git['max_size']  ||= Settings.pre_40_config ? Settings.git_max_size : 5242880 # 5.megabytes
Settings.git['bin_path']  ||= Settings.pre_40_config ? Settings.git_bin_path : '/usr/bin/git'
Settings.git['timeout']   ||= Settings.pre_40_config ? Settings.git_timeout : 10
Settings.git['path']      ||= Settings.git.bin_path # FIXME: Deprecated: remove for 4.1
