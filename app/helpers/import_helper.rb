module ImportHelper
  def has_ci_cd_only_params?
    false
  end

  def import_project_target(owner, name)
    namespace = current_user.can_create_group? ? owner : current_user.namespace_path
    "#{namespace}/#{name}"
  end

  def provider_project_link(provider, full_path)
    url = __send__("#{provider}_project_url", full_path) # rubocop:disable GitlabSecurity/PublicSend

    link_to full_path, url, target: '_blank', rel: 'noopener noreferrer'
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

  private

  def github_project_url(full_path)
    "#{github_root_url}/#{full_path}"
  end

  def github_root_url
    return @github_url if defined?(@github_url)

    provider = Gitlab.config.omniauth.providers.find { |p| p.name == 'github' }
    @github_url = provider.fetch('url', 'https://github.com') if provider
  end

  def gitea_project_url(full_path)
    "#{@gitea_host_url.sub(%r{/+\z}, '')}/#{full_path}"
  end
end
