module EE
  module ImportHelper
    extend ::Gitlab::Utils::Override

    override :has_ci_cd_only_params?
    def has_ci_cd_only_params?
      params[:ci_cd_only].present?
    end

    override :import_will_timeout_message
    def import_will_timeout_message(ci_cd_only)
      if ci_cd_only
        timeout = time_interval_in_words(::Gitlab.config.gitlab_shell.git_timeout)
        _('The connection will time out after %{timeout}. For repositories that take longer, use a clone/push combination.') % { timeout: timeout }
      else
        super
      end
    end

    override :import_svn_message
    def import_svn_message(ci_cd_only)
      if ci_cd_only
        svn_link = link_to _('this document'), help_page_path('user/project/import/svn')
        _('To connect an SVN repository, check out %{svn_link}.').html_safe % { svn_link: svn_link }
      else
        super
      end
    end

    override :import_in_progress_title
    def import_in_progress_title
      if has_ci_cd_only_params?
        _('Connecting...')
      else
        super
      end
    end

    override :import_wait_and_refresh_message
    def import_wait_and_refresh_message
      if has_ci_cd_only_params?
        _('Please wait while we connect to your repository. Refresh at will.')
      else
        super
      end
    end

    override :import_github_title
    def import_github_title
      if has_ci_cd_only_params?
        _('Connect repositories from GitHub')
      else
        super
      end
    end

    override :import_github_authorize_message
    def import_github_authorize_message
      if has_ci_cd_only_params?
        _('To connect GitHub repositories, you first need to authorize GitLab to access the list of your GitHub repositories:')
      else
        super
      end
    end

    override :import_github_personal_access_token_message
    def import_github_personal_access_token_message
      if has_ci_cd_only_params?
        personal_access_token_link = link_to _('Personal Access Token'), 'https://github.com/settings/tokens'

        if github_import_configured?
          _('Alternatively, you can use a %{personal_access_token_link}. When you create your Personal Access Token, you will need to select the <code>repo</code> scope, so we can display a list of your public and private repositories which are available to connect.').html_safe % { personal_access_token_link: personal_access_token_link }
        else
          _('To connect GitHub repositories, you can use a %{personal_access_token_link}. When you create your Personal Access Token, you will need to select the <code>repo</code> scope, so we can display a list of your public and private repositories which are available to connect.').html_safe % { personal_access_token_link: personal_access_token_link }
        end
      else
        super
      end
    end

    override :import_configure_github_admin_message
    def import_configure_github_admin_message
      if has_ci_cd_only_params?
        github_integration_link = link_to 'GitHub integration', help_page_path('integration/github')

        if current_user.admin?
          _('Note: As an administrator you may like to configure %{github_integration_link}, which will allow login via GitHub and allow connecting repositories without generating a Personal Access Token.').html_safe % { github_integration_link: github_integration_link }
        else
          _('Note: Consider asking your GitLab administrator to configure %{github_integration_link}, which will allow login via GitHub and allow connecting repositories without generating a Personal Access Token.').html_safe % { github_integration_link: github_integration_link }
        end
      else
        super
      end
    end

    override :import_githubish_choose_repository_message
    def import_githubish_choose_repository_message
      if has_ci_cd_only_params?
        _('Choose which repositories you want to connect and run CI/CD pipelines.')
      else
        super
      end
    end

    override :import_all_githubish_repositories_button_label
    def import_all_githubish_repositories_button_label
      if has_ci_cd_only_params?
        _('Connect all repositories')
      else
        super
      end
    end
  end
end
