# frozen_string_literal: true

class Projects::GoogleCloud::GcpRegionsController < Projects::GoogleCloud::BaseController
  # filtered list of GCP cloud run locations...
  #       ...that have domain mapping available
  # Source https://cloud.google.com/run/docs/locations 2022-01-30
  AVAILABLE_REGIONS = %w[asia-east1 asia-northeast1 asia-southeast1 europe-north1 europe-west1 europe-west4 us-central1 us-east1 us-east4 us-west1].freeze

  GCP_REGION_CI_VAR_KEY = 'GCP_REGION'

  def index
    @google_cloud_path = project_google_cloud_configuration_path(project)
    params = { per_page: 50 }
    branches = BranchesFinder.new(project.repository, params).execute(gitaly_pagination: true)
    tags = TagsFinder.new(project.repository, params).execute(gitaly_pagination: true)
    refs = (branches + tags).map(&:name)
    js_data = {
      availableRegions: AVAILABLE_REGIONS,
      refs: refs,
      cancelPath: project_google_cloud_configuration_path(project)
    }
    @js_data = js_data.to_json
    track_event('gcp_regions#index', 'success', js_data)
  end

  def create
    permitted_params = params.permit(:ref, :gcp_region)
    response = GoogleCloud::GcpRegionAddOrReplaceService.new(project).execute(permitted_params[:ref], permitted_params[:gcp_region])
    track_event('gcp_regions#create', 'success', response)
    redirect_to project_google_cloud_configuration_path(project), notice: _('GCP region configured')
  end
end
