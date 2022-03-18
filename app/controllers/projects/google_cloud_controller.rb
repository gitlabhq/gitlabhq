# frozen_string_literal: true

class Projects::GoogleCloudController < Projects::GoogleCloud::BaseController
  GCP_REGION_CI_VAR_KEY = 'GCP_REGION'

  def index
    js_data = {
      screen: 'home',
      serviceAccounts: GoogleCloud::ServiceAccountsService.new(project).find_for_project,
      createServiceAccountUrl: project_google_cloud_service_accounts_path(project),
      enableCloudRunUrl: project_google_cloud_deployments_cloud_run_path(project),
      enableCloudStorageUrl: project_google_cloud_deployments_cloud_storage_path(project),
      emptyIllustrationUrl: ActionController::Base.helpers.image_path('illustrations/pipelines_empty.svg'),
      configureGcpRegionsUrl: project_google_cloud_gcp_regions_path(project),
      gcpRegions: gcp_regions,
      revokeOauthUrl: revoke_oauth_url
    }
    @js_data = js_data.to_json
    track_event('google_cloud#index', 'index', js_data)
  end

  private

  def gcp_regions
    list = ::Ci::VariablesFinder.new(project, { key: GCP_REGION_CI_VAR_KEY }).execute
    list.map { |variable| { gcp_region: variable.value, environment: variable.environment_scope } }
  end

  def revoke_oauth_url
    google_token_valid = GoogleApi::CloudPlatform::Client.new(token_in_session, nil)
                                                         .validate_token(expires_at_in_session)
    google_token_valid ? project_google_cloud_revoke_oauth_index_path(project) : nil
  end
end
