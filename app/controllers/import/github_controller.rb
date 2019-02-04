# frozen_string_literal: true

class Import::GithubController < Import::BaseController
  before_action :verify_import_enabled
  before_action :provider_auth, only: [:status, :jobs, :create]

  rescue_from Octokit::Unauthorized, with: :provider_unauthorized

  def new
    if github_import_configured? && logged_in_with_provider?
      go_to_provider_for_permissions
    elsif session[access_token_key]
      redirect_to status_import_url
    end
  end

  def callback
    session[access_token_key] = client.get_token(params[:code])
    redirect_to status_import_url
  end

  def personal_access_token
    session[access_token_key] = params[:personal_access_token]&.strip
    redirect_to status_import_url
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def status
    @repos = client.repos
    @already_added_projects = find_already_added_projects(provider)
    already_added_projects_names = @already_added_projects.pluck(:import_source)

    @repos.reject! { |repo| already_added_projects_names.include? repo.full_name }
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def jobs
    render json: find_jobs(provider)
  end

  def create
    result = Import::GithubService.new(client, current_user, import_params).execute(access_params, provider)

    if result[:status] == :success
      render json: ProjectSerializer.new.represent(result[:project])
    else
      render json: { errors: result[:message] }, status: result[:http_status]
    end
  end

  private

  def import_params
    params.permit(permitted_import_params)
  end

  def permitted_import_params
    [:repo_id, :new_name, :target_namespace]
  end

  def client
    @client ||= Gitlab::LegacyGithubImport::Client.new(session[access_token_key], client_options)
  end

  def verify_import_enabled
    render_404 unless import_enabled?
  end

  def go_to_provider_for_permissions
    redirect_to client.authorize_url(callback_import_url)
  end

  def import_enabled?
    __send__("#{provider}_import_enabled?") # rubocop:disable GitlabSecurity/PublicSend
  end

  def new_import_url
    public_send("new_import_#{provider}_url", extra_import_params) # rubocop:disable GitlabSecurity/PublicSend
  end

  def status_import_url
    public_send("status_import_#{provider}_url", extra_import_params) # rubocop:disable GitlabSecurity/PublicSend
  end

  def callback_import_url
    public_send("users_import_#{provider}_callback_url", extra_import_params) # rubocop:disable GitlabSecurity/PublicSend
  end

  def provider_unauthorized
    session[access_token_key] = nil
    redirect_to new_import_url,
      alert: "Access denied to your #{Gitlab::ImportSources.title(provider.to_s)} account."
  end

  def access_token_key
    :"#{provider}_access_token"
  end

  def access_params
    { github_access_token: session[access_token_key] }
  end

  # The following methods are overridden in subclasses
  def provider
    :github
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def logged_in_with_provider?
    current_user.identities.exists?(provider: provider)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def provider_auth
    if session[access_token_key].blank?
      go_to_provider_for_permissions
    end
  end

  def client_options
    {}
  end

  def extra_import_params
    {}
  end
end
