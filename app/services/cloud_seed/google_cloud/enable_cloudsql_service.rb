# frozen_string_literal: true

module CloudSeed
  module GoogleCloud
    class EnableCloudsqlService < ::CloudSeed::GoogleCloud::BaseService
      def execute
        create_or_replace_project_vars(environment_name, 'GCP_PROJECT_ID', gcp_project_id, ci_var_protected?)

        unique_gcp_project_ids.each do |gcp_project_id|
          google_api_client.enable_cloud_sql_admin(gcp_project_id)
          google_api_client.enable_compute(gcp_project_id)
          google_api_client.enable_service_networking(gcp_project_id)
        end

        success({ gcp_project_ids: unique_gcp_project_ids })
      rescue Google::Apis::Error => err
        error(err.message)
      end

      private

      def ci_var_protected?
        ProtectedBranch.protected?(project, environment_name) || ProtectedTag.protected?(project, environment_name)
      end
    end
  end
end
