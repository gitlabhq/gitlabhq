# frozen_string_literal: true

module AlertManagement
  module HttpIntegrations
    class CreateService
      # @param project [Project]
      # @param current_user [User]
      # @param params [Hash]
      def initialize(project, current_user, params)
        @project = project
        @current_user = current_user
        @params = params.with_indifferent_access
      end

      def execute
        return error_no_permissions unless allowed?
        return error_multiple_integrations unless creation_allowed?

        integration = project.alert_management_http_integrations.create(permitted_params)
        return error_in_create(integration) unless integration.valid?

        success(integration)
      end

      private

      attr_reader :project, :current_user, :params

      def allowed?
        current_user&.can?(:admin_operations, project)
      end

      def creation_allowed?
        project.alert_management_http_integrations.empty?
      end

      def permitted_params
        params.slice(*permitted_params_keys)
      end

      # overriden in EE
      def permitted_params_keys
        %i[name active]
      end

      def error(message)
        ServiceResponse.error(message: message)
      end

      def success(integration)
        ServiceResponse.success(payload: { integration: integration })
      end

      def error_no_permissions
        error(_('You have insufficient permissions to create an HTTP integration for this project'))
      end

      def error_multiple_integrations
        error(_('Multiple HTTP integrations are not supported for this project'))
      end

      def error_in_create(integration)
        error(integration.errors.full_messages.to_sentence)
      end
    end
  end
end

::AlertManagement::HttpIntegrations::CreateService.prepend_mod_with('AlertManagement::HttpIntegrations::CreateService')
