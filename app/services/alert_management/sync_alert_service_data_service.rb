# frozen_string_literal: true

module AlertManagement
  class SyncAlertServiceDataService
    # @param alert_service [AlertsService]
    def initialize(alert_service)
      @alert_service = alert_service
    end

    def execute
      http_integration = find_http_integration

      result = if http_integration
                 update_integration_data(http_integration)
               else
                 create_integration
               end

      result ? ServiceResponse.success : ServiceResponse.error(message: 'Update failed')
    end

    private

    attr_reader :alert_service

    def find_http_integration
      AlertManagement::HttpIntegrationsFinder.new(
        alert_service.project,
        endpoint_identifier: ::AlertManagement::HttpIntegration::LEGACY_IDENTIFIER
      )
      .execute
      .first
    end

    def create_integration
      new_integration = AlertManagement::HttpIntegration.create(
        project_id: alert_service.project_id,
        name: 'HTTP endpoint',
        endpoint_identifier: AlertManagement::HttpIntegration::LEGACY_IDENTIFIER,
        active: alert_service.active,
        encrypted_token: alert_service.data.encrypted_token,
        encrypted_token_iv: alert_service.data.encrypted_token_iv
      )

      new_integration.persisted?
    end

    def update_integration_data(http_integration)
      http_integration.update(
        active: alert_service.active,
        encrypted_token: alert_service.data.encrypted_token,
        encrypted_token_iv: alert_service.data.encrypted_token_iv
      )
    end
  end
end
