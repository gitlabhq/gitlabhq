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
  end
end
