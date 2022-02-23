# frozen_string_literal: true

class Projects::GoogleCloud::GcpRegionsController < Projects::GoogleCloud::BaseController
  # filtered list of GCP cloud run locations...
  #       ...that have domain mapping available
  # Source https://cloud.google.com/run/docs/locations 2022-01-30
  AVAILABLE_REGIONS = %w[asia-east1 asia-northeast1 asia-southeast1 europe-north1 europe-west1 europe-west4 us-central1 us-east1 us-east4 us-west1].freeze

  def index
    @google_cloud_path = project_google_cloud_index_path(project)
    @js_data = {
      screen: 'gcp_regions_form',
      availableRegions: AVAILABLE_REGIONS,
      environments: project.environments,
      cancelPath: project_google_cloud_index_path(project)
    }.to_json
  end

  def create
    permitted_params = params.permit(:environment, :gcp_region)

    GoogleCloud::GcpRegionAddOrReplaceService.new(project).execute(permitted_params[:environment], permitted_params[:gcp_region])

    redirect_to project_google_cloud_index_path(project), notice: _('GCP region configured')
  end
end
