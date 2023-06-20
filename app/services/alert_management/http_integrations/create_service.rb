# frozen_string_literal: true

module AlertManagement
  module HttpIntegrations
    class CreateService < BaseService
      def execute
        return error_no_permissions unless allowed?

        ::AlertManagement::HttpIntegration.transaction do
          integration = project.alert_management_http_integrations.build(permitted_params)

          if integration.save
            @response = success(integration)

            if too_many_integrations?(integration)
              @response = error_multiple_integrations

              raise ActiveRecord::Rollback
            end
          else
            @response = error_on_save(integration)
          end
        end

        @response
      end

      private

      def error_no_permissions
        error(_('You have insufficient permissions to create an HTTP integration for this project'))
      end
    end
  end
end
