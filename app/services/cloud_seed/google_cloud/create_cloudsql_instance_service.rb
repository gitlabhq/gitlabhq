# frozen_string_literal: true

module CloudSeed
  module GoogleCloud
    DEFAULT_REGION = 'us-east1'

    class CreateCloudsqlInstanceService < ::CloudSeed::GoogleCloud::BaseService
      WORKER_INTERVAL = 30.seconds

      def execute
        create_cloud_instance
        trigger_instance_setup_worker
        success
      rescue Google::Apis::Error => err
        error(err.message)
      end

      private

      def create_cloud_instance
        google_api_client.create_cloudsql_instance(
          gcp_project_id,
          instance_name,
          root_password,
          database_version,
          region,
          tier
        )
      end

      def trigger_instance_setup_worker
        ::GoogleCloud::CreateCloudsqlInstanceWorker.perform_in(
          WORKER_INTERVAL,
          current_user.id,
          project.id,
          {
            google_oauth2_token: google_oauth2_token,
            gcp_project_id: gcp_project_id,
            instance_name: instance_name,
            database_version: database_version,
            environment_name: environment_name,
            is_protected: protected?
          }
        )
      end

      def protected?
        project.protected_for?(environment_name)
      end

      def instance_name
        # Generates an `instance_name` for the to-be-created Cloud SQL instance
        # Example: `gitlab-34647-postgres-14-staging`
        environment_alias = environment_name == '*' ? 'ALL' : environment_name
        name = "gitlab-#{project.id}-#{database_version}-#{environment_alias}"
        name.tr("_", "-").downcase
      end

      def root_password
        SecureRandom.hex(16)
      end

      def database_version
        params[:database_version]
      end

      def region
        region = ::Ci::VariablesFinder
                   .new(project, { key: Projects::GoogleCloud::GcpRegionsController::GCP_REGION_CI_VAR_KEY,
                                   environment_scope: environment_name })
                   .execute.first
        region&.value || DEFAULT_REGION
      end

      def tier
        params[:tier]
      end
    end
  end
end
