# frozen_string_literal: true

module GoogleCloud
  class EnableCloudsqlService < ::GoogleCloud::BaseService
    def execute
      return no_projects_error if unique_gcp_project_ids.empty?

      unique_gcp_project_ids.each do |gcp_project_id|
        google_api_client.enable_cloud_sql_admin(gcp_project_id)
        google_api_client.enable_compute(gcp_project_id)
        google_api_client.enable_service_networking(gcp_project_id)
      end

      success({ gcp_project_ids: unique_gcp_project_ids })
    end

    private

    def no_projects_error
      error("No GCP projects found. Configure a service account or GCP_PROJECT_ID CI variable.")
    end
  end
end
