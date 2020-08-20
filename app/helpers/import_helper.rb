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
    svn_link = link_to _('this document'), help_page_path('user/project/import/svn')
    _('To import an SVN repository, check out %{svn_link}.').html_safe % { svn_link: svn_link }
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
    _('To connect GitHub repositories, you first need to authorize GitLab to access the list of your GitHub repositories.')
  end

  def import_github_personal_access_token_message
    link_url = 'https://github.com/settings/tokens'
    link_start = '<a href="%{url}" target="_blank" rel="noopener noreferrer">'.html_safe % { url: link_url }

    html_escape(_('Create and provide your GitHub %{link_start}Personal Access Token%{link_end}. You will need to select the %{code_open}repo%{code_close} scope, so we can display a list of your public and private repositories which are available to import.')) % { link_start: link_start, link_end: '</a>'.html_safe, code_open: '<code>'.html_safe, code_close: '</code>'.html_safe }
  end

  def import_configure_github_admin_message
    github_integration_link = link_to 'GitHub integration', help_page_path('integration/github')

    if current_user.admin?
      _('Note: As an administrator you may like to configure %{github_integration_link}, which will allow login via GitHub and allow importing repositories without generating a Personal Access Token.').html_safe % { github_integration_link: github_integration_link }
    else
      _('Note: Consider asking your GitLab administrator to configure %{github_integration_link}, which will allow login via GitHub and allow importing repositories without generating a Personal Access Token.').html_safe % { github_integration_link: github_integration_link }
    end
  end
end
