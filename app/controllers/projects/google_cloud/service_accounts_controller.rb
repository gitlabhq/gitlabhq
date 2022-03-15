# frozen_string_literal: true

class Projects::GoogleCloud::ServiceAccountsController < Projects::GoogleCloud::BaseController
  before_action :validate_gcp_token!

  def index
    @google_cloud_path = project_google_cloud_index_path(project)
    google_api_client = GoogleApi::CloudPlatform::Client.new(token_in_session, nil)
    gcp_projects = google_api_client.list_projects

    if gcp_projects.empty?
      @js_data = { screen: 'no_gcp_projects' }.to_json
      track_event('service_accounts#index', 'form_error', 'no_gcp_projects')
      render status: :unauthorized, template: 'projects/google_cloud/errors/no_gcp_projects'
    else
      params = { per_page: 50 }
      branches = BranchesFinder.new(project.repository, params).execute(gitaly_pagination: true)
      tags = TagsFinder.new(project.repository, params).execute(gitaly_pagination: true)
      refs = (branches + tags).map(&:name)
      js_data = {
        screen: 'service_accounts_form',
        gcpProjects: gcp_projects,
        refs: refs,
        cancelPath: project_google_cloud_index_path(project)
      }
      @js_data = js_data.to_json

      track_event('service_accounts#index', 'form_success', js_data)
    end
  rescue Google::Apis::ClientError => error
    handle_gcp_error('service_accounts#index', error)
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

    track_event('service_accounts#create', 'form_submit', response)
    redirect_to project_google_cloud_index_path(project), notice: response.message
  rescue Google::Apis::ClientError, Google::Apis::ServerError, Google::Apis::AuthorizationError => error
    handle_gcp_error('service_accounts#create', error)
  end
end
