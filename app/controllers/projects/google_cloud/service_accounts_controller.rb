# frozen_string_literal: true

class Projects::GoogleCloud::ServiceAccountsController < Projects::GoogleCloud::BaseController
  before_action :validate_gcp_token!

  def index
    @google_cloud_path = project_google_cloud_configuration_path(project)
    google_api_client = GoogleApi::CloudPlatform::Client.new(token_in_session, nil)
    gcp_projects = google_api_client.list_projects

    if gcp_projects.empty?
      track_event('service_accounts#index', 'error_form', 'no_gcp_projects')
      flash[:warning] = _('No Google Cloud projects - You need at least one Google Cloud project')
      redirect_to project_google_cloud_configuration_path(project)
    else
      params = { per_page: 50 }
      branches = BranchesFinder.new(project.repository, params).execute(gitaly_pagination: true)
      tags = TagsFinder.new(project.repository, params).execute(gitaly_pagination: true)
      refs = (branches + tags).map(&:name)
      js_data = {
        gcpProjects: gcp_projects,
        refs: refs,
        cancelPath: project_google_cloud_configuration_path(project)
      }
      @js_data = js_data.to_json

      track_event('service_accounts#index', 'success', js_data)
    end
  rescue Google::Apis::ClientError, Google::Apis::ServerError, Google::Apis::AuthorizationError => error
    track_event('service_accounts#index', 'error_gcp', error)
    flash[:warning] = _('Google Cloud Error - %{error}') % { error: error }
    redirect_to project_google_cloud_configuration_path(project)
  end

  def create
    permitted_params = params.permit(:gcp_project, :ref)

    response = GoogleCloud::CreateServiceAccountsService.new(
      project,
      current_user,
      google_oauth2_token: token_in_session,
      gcp_project_id: permitted_params[:gcp_project],
      environment_name: permitted_params[:ref]
    ).execute

    track_event('service_accounts#create', 'success', response)
    redirect_to project_google_cloud_configuration_path(project), notice: response.message
  rescue Google::Apis::ClientError, Google::Apis::ServerError, Google::Apis::AuthorizationError => error
    track_event('service_accounts#create', 'error_gcp', error)
    flash[:warning] = _('Google Cloud Error - %{error}') % { error: error }
    redirect_to project_google_cloud_configuration_path(project)
  end
end
