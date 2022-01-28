# frozen_string_literal: true

module GoogleCloud
  class CreateServiceAccountsService < :: BaseService
    def execute
      service_account = google_api_client.create_service_account(gcp_project_id, service_account_name, service_account_desc)
      service_account_key = google_api_client.create_service_account_key(gcp_project_id, service_account.unique_id)
      google_api_client.grant_service_account_roles(gcp_project_id, service_account.email)

      service_accounts_service.add_for_project(
        environment_name,
        service_account.project_id,
        service_account.to_json,
        service_account_key.to_json,
        environment_protected?
      )

      ServiceResponse.success(message: _('Service account generated successfully'), payload: {
        service_account: service_account,
        service_account_key: service_account_key
      })
    end

    private

    def google_oauth2_token
      @params[:google_oauth2_token]
    end

    def gcp_project_id
      @params[:gcp_project_id]
    end

    def environment_name
      @params[:environment_name]
    end

    def google_api_client
      @google_api_client_instance ||= GoogleApi::CloudPlatform::Client.new(google_oauth2_token, nil)
    end

    def service_accounts_service
      GoogleCloud::ServiceAccountsService.new(project)
    end

    def service_account_name
      "GitLab :: #{project.name} :: #{environment_name}"
    end

    def service_account_desc
      "GitLab generated service account for project '#{project.name}' and environment '#{environment_name}'"
    end

    # Overridden in EE
    def environment_protected?
      false
    end
  end
end

GoogleCloud::CreateServiceAccountsService.prepend_mod
