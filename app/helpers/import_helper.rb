# frozen_string_literal: true

module ImportHelper
  include ::Gitlab::Utils::StrongMemoize

  def has_ci_cd_only_params?
    false
  end

  def sanitize_project_name(name)
    # For personal projects in Bitbucket in the form ~username, we can
    # just drop that leading tilde.
    name.gsub(/\A~+/, '').gsub(/[^\w\-]/, '-')
  end

  def import_project_target(owner, name)
    namespace = current_user.can_create_group? ? owner : current_user.namespace_path
    "#{namespace}/#{name}"
  end

  def provider_project_link_url(provider_url, full_path)
    if Gitlab::Utils.parse_url(full_path)&.absolute?
      full_path
    else
      Gitlab::Utils.append_path(provider_url, full_path)
    end
  end

  def import_will_timeout_message(_ci_cd_only)
    timeout = time_interval_in_words(Gitlab.config.gitlab_shell.git_timeout)
    _('The import will time out after %{timeout}. For repositories that take longer, use a clone/push combination.') % { timeout: timeout }
  end

  def import_svn_message(_ci_cd_only)
    svn_link = link_to _('Learn more'), help_page_path('user/project/import/_index.md', anchor: 'import-repositories-from-subversion')
    safe_format(s_('Import|You can import a Subversion repository by using third-party tools. %{svn_link}.'), svn_link: svn_link)
  end

  def import_in_progress_title
    if @project.forked?
      _('Forking in progress')
    else
      _('Import in progress')
    end
  end

  def import_wait_and_refresh_message
    _('Please wait while we import the repository for you. Refresh at will.')
  end

  def import_github_authorize_message
    s_('GithubImport|To import GitHub repositories, you must first authorize GitLab to access your GitHub repositories.')
  end

  def import_configure_github_admin_message
    github_integration_link = link_to 'GitHub integration', help_page_path('integration/github.md')

    if current_user.can_admin_all_resources?
      safe_format(_('Note: As an administrator you may like to configure %{github_integration_link}, which will allow login via GitHub and allow importing repositories without generating a personal access token.'), github_integration_link: github_integration_link)
    else
      safe_format(_('Note: Consider asking your GitLab administrator to configure %{github_integration_link}, which will allow login via GitHub and allow importing repositories without generating a personal access token.'), github_integration_link: github_integration_link)
    end
  end
end
