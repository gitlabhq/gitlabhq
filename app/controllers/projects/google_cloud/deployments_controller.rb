# frozen_string_literal: true

class Projects::GoogleCloud::DeploymentsController < Projects::GoogleCloud::BaseController
  before_action :validate_gcp_token!

  def index
    @google_cloud_path = project_google_cloud_configuration_path(project)
    js_data = {
      configurationUrl: project_google_cloud_configuration_path(project),
      deploymentsUrl: project_google_cloud_deployments_path(project),
      databasesUrl: project_google_cloud_databases_path(project),
      enableCloudRunUrl: project_google_cloud_deployments_cloud_run_path(project),
      enableCloudStorageUrl: project_google_cloud_deployments_cloud_storage_path(project)
    }
    @js_data = js_data.to_json
    track_event('deployments#index', 'success', js_data)
  end

  def cloud_run
    params = { google_oauth2_token: token_in_session }
    enable_cloud_run_response = GoogleCloud::EnableCloudRunService
                                  .new(project, current_user, params).execute

    if enable_cloud_run_response[:status] == :error
      track_event('deployments#cloud_run', 'error_enable_cloud_run', enable_cloud_run_response)
      flash[:error] = enable_cloud_run_response[:message]
      redirect_to project_google_cloud_deployments_path(project)
    else
      params = { action: GoogleCloud::GeneratePipelineService::ACTION_DEPLOY_TO_CLOUD_RUN }
      generate_pipeline_response = GoogleCloud::GeneratePipelineService
                                     .new(project, current_user, params).execute

      if generate_pipeline_response[:status] == :error
        track_event('deployments#cloud_run', 'error_generate_pipeline', generate_pipeline_response)
        flash[:error] = 'Failed to generate pipeline'
        redirect_to project_google_cloud_deployments_path(project)
      else
        cloud_run_mr_params = cloud_run_mr_params(generate_pipeline_response[:branch_name])
        track_event('deployments#cloud_run', 'success', cloud_run_mr_params)
        redirect_to project_new_merge_request_path(project, merge_request: cloud_run_mr_params)
      end
    end
  rescue Google::Apis::ClientError, Google::Apis::ServerError, Google::Apis::AuthorizationError => error
    track_event('deployments#cloud_run', 'error_gcp', error)
    flash[:warning] = _('Google Cloud Error - %{error}') % { error: error }
    redirect_to project_google_cloud_deployments_path(project)
  end

  def cloud_storage
    render json: "Placeholder"
  end

  private

  def cloud_run_mr_params(branch_name)
    {
      title: cloud_run_mr_title,
      description: cloud_run_mr_description(branch_name),
      source_project_id: project.id,
      target_project_id: project.id,
      source_branch: branch_name,
      target_branch: project.default_branch
    }
  end

  def cloud_run_mr_title
    'Enable deployments to Cloud Run'
  end

  def cloud_run_mr_description(branch_name)
    <<-TEXT
This merge request includes a Cloud Run deployment job in the pipeline definition (.gitlab-ci.yml).

The `deploy-to-cloud-run` job:
* Requires the following environment variables
    * `GCP_PROJECT_ID`
    * `GCP_SERVICE_ACCOUNT_KEY`
* Job definition can be found at: https://gitlab.com/gitlab-org/incubation-engineering/five-minute-production/library

This pipeline definition has been committed to the branch `#{branch_name}`.
You may modify the pipeline definition further or accept the changes as-is if suitable.
    TEXT
  end
end
