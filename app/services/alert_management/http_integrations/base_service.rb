# frozen_string_literal: true

module AlertManagement
  module HttpIntegrations
    class BaseService < BaseProjectService
      # @param project [Project]
      # @param current_user [User]
      # @param params [Hash]
      def initialize(project, current_user, params)
        @response = nil

        super(project: project, current_user: current_user, params: params.with_indifferent_access)
      end

      private

      def allowed?
        current_user&.can?(:admin_operations, project)
      end

      def too_many_integrations?(integration)
        AlertManagement::HttpIntegration
          .for_project(integration.project_id)
          .for_type(integration.type_identifier)
          .id_not_in(integration.id)
          .any?
      end

      def permitted_params
        params.slice(*permitted_params_keys)
      end

      # overriden in EE
      def permitted_params_keys
        %i[name active type_identifier]
      end

      def error(message)
        ServiceResponse.error(message: message)
      end

      def success(integration)
        ServiceResponse.success(payload: { integration: integration.reset })
      end

      def error_multiple_integrations
        error(_('Multiple integrations of a single type are not supported for this project'))
      end

      def error_on_save(integration)
        error(integration.errors.full_messages.to_sentence)
      end
    end
  end
end

::AlertManagement::HttpIntegrations::BaseService.prepend_mod
