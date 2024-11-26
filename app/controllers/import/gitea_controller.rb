# frozen_string_literal: true

class Import::GiteaController < Import::GithubController
  extend ::Gitlab::Utils::Override

  before_action :verify_blocked_uri, only: :status

  def new
    redirect_to status_import_url if session[access_token_key].present? && provider_url.present?
  end

  def personal_access_token
    session[host_key] = params[host_key]
    super
  end

  def status
    # Request repos to display error page if provider token is invalid
    # Improving in https://gitlab.com/gitlab-org/gitlab/-/issues/25859
    client_repos

    respond_to do |format|
      format.json do
        render json: { imported_projects: serialized_imported_projects,
                       provider_repos: serialized_provider_repos,
                       incompatible_repos: serialized_incompatible_repos }
      end

      format.html do
        if params[:namespace_id].present?
          @namespace = Namespace.find_by_id(params[:namespace_id])

          render_404 unless current_user.can?(:import_projects, @namespace)
        end
      end
    end
  end

  protected

  override :provider_name
  def provider_name
    :gitea
  end

  private

  def host_key
    :"#{provider_name}_host_url"
  end

  override :provider_url
  def provider_url
    session[host_key]
  end

  # Gitea is not yet an OAuth provider
  # See https://github.com/go-gitea/gitea/issues/27
  override :logged_in_with_provider?
  def logged_in_with_provider?
    false
  end

  override :provider_auth
  def provider_auth
    if session[access_token_key].blank? || provider_url.blank?
      redirect_to new_import_gitea_url,
        alert: _('You need to specify both an access token and a Host URL.')
    end
  end

  override :serialized_imported_projects
  def serialized_imported_projects(projects = already_added_projects)
    ProjectSerializer.new.represent(projects, serializer: :import, provider_url: provider_url)
  end

  override :client_repos
  def client_repos
    @client_repos ||= filtered(client.repos)
  end

  def client
    @client ||= Gitlab::LegacyGithubImport::Client.new(session[access_token_key], **client_options)
  end

  def client_options
    verified_url, provider_hostname = verify_blocked_uri

    {
      host: verified_url.scheme == 'https' ? provider_url : verified_url.to_s,
      api_version: 'v1',
      hostname: provider_hostname
    }
  end

  def verify_blocked_uri
    @verified_url_and_hostname ||= Gitlab::HTTP_V2::UrlBlocker.validate!(
      provider_url,
      allow_localhost: allow_local_requests?,
      allow_local_network: allow_local_requests?,
      schemes: %w[http https],
      deny_all_requests_except_allowed: Gitlab::CurrentSettings.deny_all_requests_except_allowed?,
      outbound_local_requests_allowlist: Gitlab::CurrentSettings.outbound_local_requests_whitelist # rubocop:disable Naming/InclusiveLanguage -- existing setting
    )
  rescue Gitlab::HTTP_V2::UrlBlocker::BlockedUrlError => e
    session[access_token_key] = nil

    redirect_to new_import_url, alert: _('Specified URL cannot be used: "%{reason}"') % { reason: e.message }
  end

  def allow_local_requests?
    Gitlab::CurrentSettings.allow_local_requests_from_web_hooks_and_services?
  end
end
