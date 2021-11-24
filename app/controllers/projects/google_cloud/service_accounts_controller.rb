# frozen_string_literal: true

class Projects::GoogleCloud::ServiceAccountsController < Projects::GoogleCloud::BaseController
  before_action :validate_gcp_token!

  def index
    @google_cloud_path = project_google_cloud_index_path(project)
    google_api_client = GoogleApi::CloudPlatform::Client.new(token_in_session, nil)
    gcp_projects = google_api_client.list_projects

    if gcp_projects.empty?
      @js_data = {}.to_json
      render status: :unauthorized, template: 'projects/google_cloud/errors/no_gcp_projects'
    else
      @js_data = {
        gcpProjects: gcp_projects,
        environments: project.environments,
        cancelPath: project_google_cloud_index_path(project)
      }.to_json
    end
  rescue Google::Apis::ClientError => error
    handle_gcp_error(error, project)
  end

  def create
    google_api_client = GoogleApi::CloudPlatform::Client.new(token_in_session, nil)
    service_accounts_service = GoogleCloud::ServiceAccountsService.new(project)
    gcp_project = params[:gcp_project]
    environment = params[:environment]
    generated_name = "GitLab :: #{@project.name} :: #{environment}"
    generated_desc = "GitLab generated service account for project '#{@project.name}' and environment '#{environment}'"

    service_account = google_api_client.create_service_account(gcp_project, generated_name, generated_desc)
    service_account_key = google_api_client.create_service_account_key(gcp_project, service_account.unique_id)

    service_accounts_service.add_for_project(
      environment,
      service_account.project_id,
      service_account.to_json,
      service_account_key.to_json
    )

    redirect_to project_google_cloud_index_path(project), notice: _('Service account generated successfully')
  rescue Google::Apis::ClientError, Google::Apis::ServerError, Google::Apis::AuthorizationError => error
    handle_gcp_error(error, project)
  end

  private

  def validate_gcp_token!
    is_token_valid = GoogleApi::CloudPlatform::Client.new(token_in_session, nil)
                                                     .validate_token(expires_at_in_session)

    return if is_token_valid

    return_url = project_google_cloud_service_accounts_path(project)
    state = generate_session_key_redirect(request.url, return_url)
    @authorize_url = GoogleApi::CloudPlatform::Client.new(nil,
                                                          callback_google_api_auth_url,
                                                          state: state).authorize_url
    redirect_to @authorize_url
  end

  def generate_session_key_redirect(uri, error_uri)
    GoogleApi::CloudPlatform::Client.new_session_key_for_redirect_uri do |key|
      session[key] = uri
      session[:error_uri] = error_uri
    end
  end

  def token_in_session
    session[GoogleApi::CloudPlatform::Client.session_key_for_token]
  end

  def expires_at_in_session
    session[GoogleApi::CloudPlatform::Client.session_key_for_expires_at]
  end

  def handle_gcp_error(error, project)
    Gitlab::ErrorTracking.track_exception(error, project_id: project.id)
    @js_data = { error: error.to_s }.to_json
    render status: :unauthorized, template: 'projects/google_cloud/errors/gcp_error'
  end
end
