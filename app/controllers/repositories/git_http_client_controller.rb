# frozen_string_literal: true

module Repositories
  class GitHttpClientController < ::Repositories::ApplicationController
    include ActionController::HttpAuthentication::Basic
    include KerberosHelper
    include Gitlab::Utils::StrongMemoize

    attr_reader :authentication_result, :redirected_path

    delegate :authentication_abilities, to: :authentication_result, allow_nil: true
    delegate :type, to: :authentication_result, allow_nil: true, prefix: :auth_result

    # Git clients will not know what authenticity token to send along
    skip_around_action :set_session_storage
    skip_before_action :verify_authenticity_token

    prepend_before_action :authenticate_user, :parse_repo_path

    skip_around_action :sessionless_bypass_admin_mode!
    around_action :bypass_admin_mode!, if: :authenticated_user

    feature_category :source_code_management

    def authenticated_user
      authentication_result&.user || authentication_result&.deploy_token
    end

    private

    def user
      authenticated_user
    end

    def download_request?
      raise NotImplementedError
    end

    def upload_request?
      raise NotImplementedError
    end

    def authenticate_user
      @authentication_result = Gitlab::Auth::Result::EMPTY

      if allow_basic_auth? && basic_auth_provided?
        login, password = user_name_and_password(request)

        if handle_basic_authentication(login, password)
          return # Allow access
        end
      elsif allow_kerberos_auth? && spnego_provided?
        kerberos_user = find_kerberos_user

        if kerberos_user
          @authentication_result = Gitlab::Auth::Result.new(
            kerberos_user, nil, :kerberos, Gitlab::Auth.full_authentication_abilities)

          send_final_spnego_response
          return # Allow access
        end
      elsif http_download_allowed?

        @authentication_result = Gitlab::Auth::Result.new(nil, project, :none, [:download_code])

        return # Allow access
      end

      send_challenges
      render_access_denied
    rescue Gitlab::Auth::MissingPersonalAccessTokenError
      render_access_denied
    end

    def render_access_denied
      help_page = help_page_url(
        'topics/git/troubleshooting_git.md',
        anchor: 'error-on-git-fetch-http-basic-access-denied'
      )

      render(
        plain: format(_("HTTP Basic: Access denied. If a password was provided for Git authentication, the password was incorrect or you're required to use a token instead of a password. If a token was provided, it was either incorrect, expired, or improperly scoped. See %{help_page_url}"), help_page_url: help_page),
        status: :unauthorized
      )
    end

    def basic_auth_provided?
      has_basic_credentials?(request)
    end

    def send_challenges
      challenges = []
      challenges << 'Basic realm="GitLab"' if allow_basic_auth?
      challenges << spnego_challenge if allow_kerberos_auth?
      headers['Www-Authenticate'] = challenges.join("\n") if challenges.any?
    end

    def container
      parse_repo_path unless defined?(@container)

      @container
    end

    def project
      parse_repo_path unless defined?(@project)

      @project
    end

    def repository_path
      @repository_path ||= params[:repository_path]
    end

    def parse_repo_path
      @container, @project, @repo_type, @redirected_path = Gitlab::RepoPath.parse(repository_path)
    end

    def repository
      strong_memoize(:repository) do
        repo_type.repository_for(container)
      end
    end

    def repo_type
      parse_repo_path unless defined?(@repo_type)

      @repo_type
    end

    def handle_basic_authentication(login, password)
      @authentication_result = Gitlab::Auth.find_for_git_client(
        login, password, project: project, request: request)

      @authentication_result.success?
    end

    def ci?
      authentication_result.ci?(project)
    end

    def http_download_allowed?
      Gitlab::ProtocolAccess.allowed?('http') &&
        download_request? &&
        container &&
        ::Users::Anonymous.can?(repo_type.guest_read_ability, container)
    end

    def bypass_admin_mode!(&block)
      return yield unless Gitlab::CurrentSettings.admin_mode

      Gitlab::Auth::CurrentUserMode.bypass_session!(authenticated_user.id, &block)
    end
  end
end

::Repositories::GitHttpClientController.prepend_mod_with('Repositories::GitHttpClientController')
