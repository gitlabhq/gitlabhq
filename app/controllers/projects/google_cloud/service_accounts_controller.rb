# frozen_string_literal: true

class Projects::GoogleCloud::ServiceAccountsController < Projects::GoogleCloud::BaseController
  before_action :validate_gcp_token!

  def index
    if gcp_projects.empty?
      track_event(:error_no_gcp_projects)
      flash[:warning] = _('No Google Cloud projects - You need at least one Google Cloud project')
      redirect_to project_google_cloud_configuration_path(project)
    else
      js_data = {
        gcpProjects: gcp_projects,
        refs: refs,
        cancelPath: project_google_cloud_configuration_path(project)
      }
      @js_data = Gitlab::Json.dump(js_data)

      track_event(:render_form)
    end
  rescue Google::Apis::Error => e
    track_event(:error_google_api)
    flash[:warning] = _('Google Cloud Error - %{error}') % { error: e }
    redirect_to project_google_cloud_configuration_path(project)
  end

  def create
    permitted_params = params.permit(:gcp_project, :ref)

    response = CloudSeed::GoogleCloud::CreateServiceAccountsService.new(
      project,
      current_user,
      google_oauth2_token: token_in_session,
      gcp_project_id: permitted_params[:gcp_project],
      environment_name: permitted_params[:ref]
    ).execute

    track_event(:create_service_account)
    redirect_to project_google_cloud_configuration_path(project), notice: response.message
  rescue Google::Apis::Error => e
    track_event(:error_google_api)
    flash[:warning] = _('Google Cloud Error - %{error}') % { error: e }
    redirect_to project_google_cloud_configuration_path(project)
  end
end
