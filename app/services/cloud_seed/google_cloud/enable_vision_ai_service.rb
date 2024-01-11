# frozen_string_literal: true

module CloudSeed
  module GoogleCloud
    class EnableVisionAiService < ::CloudSeed::GoogleCloud::BaseService
      def execute
        gcp_project_ids = unique_gcp_project_ids

        if gcp_project_ids.empty?
          error("No GCP projects found. Configure a service account or GCP_PROJECT_ID ci variable.")
        else
          gcp_project_ids.each do |gcp_project_id|
            google_api_client.enable_vision_api(gcp_project_id)
          end

          success({ gcp_project_ids: gcp_project_ids })
        end
      end
    end
  end
end
