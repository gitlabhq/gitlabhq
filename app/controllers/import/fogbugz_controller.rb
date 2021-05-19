# frozen_string_literal: true

class Import::FogbugzController < Import::BaseController
  extend ::Gitlab::Utils::Override

  before_action :verify_fogbugz_import_enabled
  before_action :user_map, only: [:new_user_map, :create_user_map]
  before_action :verify_blocked_uri, only: :callback

  rescue_from Fogbugz::AuthenticationException, with: :fogbugz_unauthorized

  def new
  end

  def callback
    begin
      res = Gitlab::FogbugzImport::Client.new(import_params.to_h.symbolize_keys)
    rescue StandardError
      # If the URI is invalid various errors can occur
      return redirect_to new_import_fogbugz_path, alert: _('Could not connect to FogBugz, check your URL')
    end
    session[:fogbugz_token] = res.get_token
    session[:fogbugz_uri] = params[:uri]

    redirect_to new_user_map_import_fogbugz_path
  end

  def new_user_map
  end

  def create_user_map
    user_map = user_map_params.to_h[:users]

    unless user_map.is_a?(Hash) && user_map.all? { |k, v| !v[:name].blank? }
      flash.now[:alert] = _('All users must have a name.')

      return render 'new_user_map'
    end

    session[:fogbugz_user_map] = user_map

    flash[:notice] = _('The user map has been saved. Continue by selecting the projects you want to import.')

    redirect_to status_import_fogbugz_path
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def status
    unless client.valid?
      return redirect_to new_import_fogbugz_path
    end

    super
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def realtime_changes
    super
  end

  def create
    repo = client.repo(params[:repo_id])
    fb_session = { uri: session[:fogbugz_uri], token: session[:fogbugz_token] }
    umap = session[:fogbugz_user_map] || client.user_map

    project = Gitlab::FogbugzImport::ProjectCreator.new(repo, fb_session, current_user.namespace, current_user, umap).execute

    if project.persisted?
      render json: ProjectSerializer.new.represent(project, serializer: :import)
    else
      render json: { errors: project_save_error(project) }, status: :unprocessable_entity
    end
  end

  protected

  # rubocop: disable CodeReuse/ActiveRecord
  override :importable_repos
  def importable_repos
    repos = client.repos

    already_added_projects_names = already_added_projects.map(&:import_source)

    repos.reject { |repo| already_added_projects_names.include? repo.name }
  end
  # rubocop: enable CodeReuse/ActiveRecord

  override :incompatible_repos
  def incompatible_repos
    []
  end

  override :provider_name
  def provider_name
    :fogbugz
  end

  override :provider_url
  def provider_url
    session[:fogbugz_uri]
  end

  private

  def client
    @client ||= Gitlab::FogbugzImport::Client.new(token: session[:fogbugz_token], uri: session[:fogbugz_uri])
  end

  def user_map
    @user_map ||= begin
      user_map = client.user_map

      stored_user_map = session[:fogbugz_user_map]
      user_map.update(stored_user_map) if stored_user_map

      user_map
    end
  end

  def fogbugz_unauthorized(exception)
    redirect_to new_import_fogbugz_path, alert: exception.message
  end

  def import_params
    params.permit(:uri, :email, :password)
  end

  def user_map_params
    params.permit(users: %w(name email gitlab_user))
  end

  def verify_fogbugz_import_enabled
    render_404 unless fogbugz_import_enabled?
  end

  def verify_blocked_uri
    Gitlab::UrlBlocker.validate!(
      params[:uri],
      allow_localhost: allow_local_requests?,
      allow_local_network: allow_local_requests?,
      schemes: %w(http https)
    )
  rescue Gitlab::UrlBlocker::BlockedUrlError => e
    redirect_to new_import_fogbugz_url, alert: _('Specified URL cannot be used: "%{reason}"') % { reason: e.message }
  end

  def allow_local_requests?
    Gitlab::CurrentSettings.allow_local_requests_from_web_hooks_and_services?
  end
end
