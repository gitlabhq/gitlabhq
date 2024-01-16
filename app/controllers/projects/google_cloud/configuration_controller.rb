# frozen_string_literal: true

module Projects
  module GoogleCloud
    class ConfigurationController < Projects::GoogleCloud::BaseController
      def index
        js_data = {
          configurationUrl: project_google_cloud_configuration_path(project),
          deploymentsUrl: project_google_cloud_deployments_path(project),
          databasesUrl: project_google_cloud_databases_path(project),
          serviceAccounts: ::CloudSeed::GoogleCloud::ServiceAccountsService.new(project).find_for_project,
          createServiceAccountUrl: project_google_cloud_service_accounts_path(project),
          emptyIllustrationUrl:
            ActionController::Base.helpers.image_path('illustrations/empty-state/empty-pipeline-md.svg'),
          configureGcpRegionsUrl: project_google_cloud_gcp_regions_path(project),
          gcpRegions: gcp_regions,
          revokeOauthUrl: revoke_oauth_url
        }
        @js_data = Gitlab::Json.dump(js_data)
        track_event(:render_page)
      end

      private

      def gcp_regions
        params = { key: Projects::GoogleCloud::GcpRegionsController::GCP_REGION_CI_VAR_KEY }
        list = ::Ci::VariablesFinder.new(project, params).execute
        list.map { |variable| { gcp_region: variable.value, environment: variable.environment_scope } }
      end

      def revoke_oauth_url
        google_token_valid = GoogleApi::CloudPlatform::Client.new(token_in_session, nil)
                                                             .validate_token(expires_at_in_session)
        google_token_valid ? project_google_cloud_revoke_oauth_index_path(project) : nil
      end
    end
  end
end
