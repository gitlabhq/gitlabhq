# frozen_string_literal: true

class Projects::GoogleCloud::ServiceAccountsController < Projects::GoogleCloud::BaseController
  before_action :validate_gcp_token!

  def index
    @google_cloud_path = project_google_cloud_index_path(project)
    google_api_client = GoogleApi::CloudPlatform::Client.new(token_in_session, nil)
    gcp_projects = google_api_client.list_projects

    if gcp_projects.empty?
      @js_data = { screen: 'no_gcp_projects' }.to_json
      render status: :unauthorized, template: 'projects/google_cloud/errors/no_gcp_projects'
    else
      @js_data = {
        screen: 'service_accounts_form',
        gcpProjects: gcp_projects,
        environments: project.environments,
        cancelPath: project_google_cloud_index_path(project)
      }.to_json
    end
  rescue Google::Apis::ClientError => error
    handle_gcp_error(error, project)
  end

  def create
    response = GoogleCloud::CreateServiceAccountsService.new(
      project,
      current_user,
      google_oauth2_token: token_in_session,
      gcp_project_id: params[:gcp_project],
      environment_name: params[:environment]
    ).execute

    redirect_to project_google_cloud_index_path(project), notice: response.message
  rescue Google::Apis::ClientError, Google::Apis::ServerError, Google::Apis::AuthorizationError => error
    handle_gcp_error(error, project)
  end
end
