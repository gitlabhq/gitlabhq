# frozen_string_literal: true

module CloudSeed
  module GoogleCloud
    class CreateServiceAccountsService < ::CloudSeed::GoogleCloud::BaseService
      def execute
        service_account = google_api_client.create_service_account(gcp_project_id, service_account_name, service_account_desc)
        service_account_key = google_api_client.create_service_account_key(gcp_project_id, service_account.unique_id)
        google_api_client.grant_service_account_roles(gcp_project_id, service_account.email)

        service_accounts_service.add_for_project(
          environment_name,
          service_account.project_id,
          Gitlab::Json.dump(service_account),
          Gitlab::Json.dump(service_account_key),
          ProtectedBranch.protected?(project, environment_name) || ProtectedTag.protected?(project, environment_name)
        )

        ServiceResponse.success(message: _('Service account generated successfully'), payload: {
          service_account: service_account,
          service_account_key: service_account_key
        })
      end

      private

      def service_accounts_service
        GoogleCloud::ServiceAccountsService.new(project)
      end

      def service_account_name
        "GitLab :: #{project.name} :: #{environment_name}"
      end

      def service_account_desc
        "GitLab generated service account for project '#{project.name}' and environment '#{environment_name}'"
      end
    end
  end
end

CloudSeed::GoogleCloud::CreateServiceAccountsService.prepend_mod
