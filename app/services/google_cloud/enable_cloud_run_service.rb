# frozen_string_literal: true

module GoogleCloud
  class EnableCloudRunService < :: BaseService
    def execute
      gcp_project_ids = unique_gcp_project_ids

      if gcp_project_ids.empty?
        error("No GCP projects found. Configure a service account or GCP_PROJECT_ID ci variable.")
      else
        google_api_client = GoogleApi::CloudPlatform::Client.new(token_in_session, nil)

        gcp_project_ids.each do |gcp_project_id|
          google_api_client.enable_cloud_run(gcp_project_id)
          google_api_client.enable_artifacts_registry(gcp_project_id)
          google_api_client.enable_cloud_build(gcp_project_id)
        end

        success({ gcp_project_ids: gcp_project_ids })
      end
    end

    private

    def unique_gcp_project_ids
      all_gcp_project_ids = project.variables.filter { |var| var.key == 'GCP_PROJECT_ID' }.map { |var| var.value }
      all_gcp_project_ids.uniq
    end

    def token_in_session
      @params[:token_in_session]
    end
  end
end
