# frozen_string_literal: true

class Import::GithubController < Import::BaseController
  extend ::Gitlab::Utils::Override

  include ImportHelper
  include ActionView::Helpers::SanitizeHelper
  include Import::GithubOauth

  before_action :verify_import_enabled
  before_action :provider_auth, only: [:status, :realtime_changes, :create]
  before_action :expire_etag_cache, only: [:status, :create]

  rescue_from Octokit::Unauthorized, with: :provider_unauthorized
  rescue_from Octokit::TooManyRequests, with: :provider_rate_limit
  rescue_from Gitlab::GithubImport::RateLimitError, with: :rate_limit_threshold_exceeded

  delegate :client, to: :client_proxy, private: true

  PAGE_LENGTH = 25

  def new
    if !ci_cd_only? && github_import_configured? && logged_in_with_provider?
      go_to_provider_for_permissions
    elsif session[access_token_key]
      redirect_to status_import_url
    end
  end

  def callback
    auth_state = session.delete(auth_state_key)

    if auth_state.blank? || !ActiveSupport::SecurityUtils.secure_compare(auth_state, params[:state])
      provider_unauthorized
    else
      session[access_token_key] = get_token(params[:code])
      redirect_to status_import_url
    end
  end

  def personal_access_token
    session[access_token_key] = params[:personal_access_token]&.strip
    redirect_to status_import_url
  end

  def status
    # Request repos to display error page if provider token is invalid
    # Improving in https://gitlab.com/gitlab-org/gitlab-foss/issues/55585
    client_repos

    respond_to do |format|
      format.json do
        render json: { imported_projects: serialized_imported_projects,
                       provider_repos: serialized_provider_repos,
                       incompatible_repos: serialized_incompatible_repos,
                       page_info: client_repos_response[:page_info] }
      end

      format.html do
        if params[:namespace_id].present?
          @namespace = Namespace.find_by_id(params[:namespace_id])

          render_404 unless current_user.can?(:create_projects, @namespace)
        end
      end
    end
  end

  def create
    result = Import::GithubService.new(client, current_user, import_params).execute(access_params, provider_name)

    if result[:status] == :success
      render json: serialized_imported_projects(result[:project])
    else
      render json: { errors: result[:message] }, status: result[:http_status]
    end
  end

  def realtime_changes
    Gitlab::PollingInterval.set_header(response, interval: 3_000)

    render json: already_added_projects.map { |project|
      {
        id: project.id,
        import_status: project.import_status,
        stats: ::Gitlab::GithubImport::ObjectCounter.summary(project)
      }
    }
  end

  def cancel
    project = Project.imported_from(provider_name).find(params[:project_id])
    result = Import::Github::CancelProjectImportService.new(project, current_user).execute

    if result[:status] == :success
      render json: serialized_imported_projects(result[:project])
    else
      render json: { errors: result[:message] }, status: result[:http_status]
    end
  end

  protected

  override :importable_repos
  def importable_repos
    client_repos.to_a
  end

  override :incompatible_repos
  def incompatible_repos
    []
  end

  override :provider_name
  def provider_name
    :github
  end

  override :provider_url
  def provider_url
    strong_memoize(:provider_url) do
      oauth_config&.dig('url').presence || 'https://github.com'
    end
  end

  private

  def import_params
    params.permit(permitted_import_params)
  end

  def permitted_import_params
    [:repo_id, :new_name, :target_namespace, { optional_stages: {} }]
  end

  def serialized_imported_projects(projects = already_added_projects)
    ProjectSerializer.new.represent(projects, serializer: :import, provider_url: provider_url)
  end

  def expire_etag_cache
    Gitlab::EtagCaching::Store.new.tap do |store|
      store.touch(realtime_changes_path)
    end
  end

  def client_proxy
    @client_proxy ||= Gitlab::GithubImport::Clients::Proxy.new(
      session[access_token_key], client_options
    )
  end

  def client_repos_response
    @client_repos_response ||= client_proxy.repos(sanitized_filter_param, fetch_repos_options)
  end

  def client_repos
    client_repos_response[:repos]
  end

  def sanitized_filter_param
    super

    @filter = sanitize_query_param(@filter)
  end

  def sanitize_query_param(value)
    value.to_s.first(255).gsub(/[ :]/, '')
  end

  def verify_import_enabled
    render_404 unless import_enabled?
  end

  def import_enabled?
    __send__("#{provider_name}_import_enabled?") # rubocop:disable GitlabSecurity/PublicSend
  end

  def realtime_changes_path
    public_send("realtime_changes_import_#{provider_name}_path", format: :json) # rubocop:disable GitlabSecurity/PublicSend
  end

  def new_import_url
    public_send("new_import_#{provider_name}_url", extra_import_params.merge({ namespace_id: params[:namespace_id] })) # rubocop:disable GitlabSecurity/PublicSend
  end

  def status_import_url
    public_send("status_import_#{provider_name}_url", extra_import_params.merge({ namespace_id: params[:namespace_id].presence })) # rubocop:disable GitlabSecurity/PublicSend
  end

  def provider_unauthorized
    session[access_token_key] = nil
    redirect_to new_import_url,
      alert: "Access denied to your #{Gitlab::ImportSources.title(provider_name.to_s)} account."
  end

  def provider_rate_limit(exception)
    reset_time = Time.zone.at(exception.response_headers['x-ratelimit-reset'].to_i)
    session[access_token_key] = nil
    redirect_to new_import_url,
      alert: _("GitHub API rate limit exceeded. Try again after %{reset_time}") % { reset_time: reset_time }
  end

  def auth_state_key
    :"#{provider_name}_auth_state_key"
  end

  def access_token_key
    :"#{provider_name}_access_token"
  end

  def access_params
    { github_access_token: session[access_token_key] }
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def logged_in_with_provider?
    current_user.identities.exists?(provider: provider_name)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def client_options
    { wait_for_rate_limit_reset: false }
  end

  def rate_limit_threshold_exceeded
    head :too_many_requests
  end

  def fetch_repos_options
    pagination_options.merge(relation_options)
  end

  def pagination_options
    {
      before: params[:before].presence,
      after: params[:after].presence,
      first: PAGE_LENGTH,
      # TODO: remove after rollout FF github_client_fetch_repos_via_graphql
      # https://gitlab.com/gitlab-org/gitlab/-/issues/385649
      page: [1, params[:page].to_i].max,
      per_page: PAGE_LENGTH
    }
  end

  def relation_options
    {
      relation_type: params[:relation_type],
      organization_login: sanitize_query_param(params[:organization_login])
    }
  end
end

Import::GithubController.prepend_mod_with('Import::GithubController')
