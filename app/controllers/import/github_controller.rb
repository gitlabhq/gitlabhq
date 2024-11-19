# frozen_string_literal: true

class Import::GithubController < Import::BaseController
  extend ::Gitlab::Utils::Override

  include ImportHelper
  include SafeFormatHelper
  include ActionView::Helpers::SanitizeHelper
  include Import::GithubOauth

  before_action :authorize_owner_access!, except: [:new, :callback, :personal_access_token, :status, :details, :create,
    :realtime_changes, :cancel_all, :counts]
  before_action :verify_import_enabled
  before_action :provider_auth, only: [:status, :realtime_changes, :create]
  before_action :expire_etag_cache, only: [:status, :create]

  rescue_from Octokit::Unauthorized, with: :provider_unauthorized
  rescue_from Octokit::TooManyRequests, with: :provider_rate_limit
  rescue_from Octokit::Forbidden, with: :provider_forbidden
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
    client_repos

    respond_to do |format|
      format.json do
        render json: { imported_projects: serialized_imported_projects,
                       provider_repos: serialized_provider_repos,
                       incompatible_repos: serialized_incompatible_repos,
                       page_info: client_repos_response[:page_info],
                       provider_repo_count: client_repos_response[:count] }
      end

      format.html do
        if params[:namespace_id].present?
          @namespace = Namespace.find_by_id(params[:namespace_id])

          render_404 unless current_user.can?(:import_projects, @namespace)
        end
      end
    end
  end

  def details; end

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

    render json: Import::GithubRealtimeRepoSerializer.new.represent(already_added_projects)
  end

  def failures
    unless project.import_finished?
      return render status: :bad_request, json: {
        message: _('The import is not complete.')
      }
    end

    failures = project.import_failures.with_external_identifiers
    serializer = Import::GithubFailureSerializer.new.with_pagination(request, response)

    render json: serializer.represent(failures)
  end

  def cancel
    result = Import::Github::CancelProjectImportService.new(project, current_user).execute

    if result[:status] == :success
      render json: serialized_imported_projects(result[:project])
    else
      render json: { errors: result[:message] }, status: result[:http_status]
    end
  end

  def cancel_all
    projects_to_cancel = Project.imported_from(provider_name).created_by(current_user).is_importing

    canceled = projects_to_cancel.map do |project|
      # #reset is called to make sure project was not finished/canceled brefore calling service
      result = Import::Github::CancelProjectImportService.new(project.reset, current_user).execute

      {
        id: project.id,
        status: result[:status],
        error: result[:message]
      }.compact
    end

    render json: canceled
  end

  def counts
    render json: {
      owned: client_proxy.count_repos_by('owned', current_user.id),
      collaborated: client_proxy.count_repos_by('collaborated', current_user.id),
      organization: client_proxy.count_repos_by('organization', current_user.id)
    }
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
    oauth_config&.dig('url').presence || 'https://github.com'
  end
  strong_memoize_attr :provider_url

  private

  def project
    @project ||= Project.imported_from(provider_name).find(params[:project_id])
  end

  def authorize_owner_access!
    render_404 unless current_user.can?(:owner_access, project)
  end

  def import_params
    params.permit(permitted_import_params)
  end

  def permitted_import_params
    [:repo_id, :new_name, :target_namespace, { optional_stages: {} }]
  end

  def serialized_imported_projects(projects = already_added_projects)
    ProjectSerializer.new.represent(
      projects,
      serializer: :import, provider_url: provider_url, client: client_proxy
    )
  end

  def expire_etag_cache
    Gitlab::EtagCaching::Store.new.tap do |store|
      store.touch(realtime_changes_path)
    end
  end

  def client_proxy
    @client_proxy ||= Gitlab::GithubImport::Clients::Proxy.new(
      session[access_token_key]
    )
  end

  def client_repos_response
    @client_repos_response ||= client_proxy.repos(sanitized_filter_param, fetch_repos_options)
  end

  def client_repos
    # Request repos to display error page if provider token is invalid
    # Improving in https://gitlab.com/gitlab-org/gitlab-foss/issues/55585
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

  def provider_forbidden
    session[access_token_key] = nil
    docs_link = helpers.link_to(
      '',
      help_page_url('user/project/import/github.md', anchor: 'use-a-github-personal-access-token'),
      target: '_blank',
      rel: 'noopener noreferrer'
    )
    tag_pair_docs_link = tag_pair(docs_link, :link_start, :link_end)
    alert_message = safe_format(
      s_(
        "GithubImport|Your GitHub personal access token does not have the required scope to import. " \
          "%{link_start}Learn More%{link_end}."
      ),
      tag_pair_docs_link
    )

    redirect_to new_import_url, alert: alert_message
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
      first: PAGE_LENGTH
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
