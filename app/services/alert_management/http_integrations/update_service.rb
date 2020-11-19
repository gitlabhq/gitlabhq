# frozen_string_literal: true

module AlertManagement
  module HttpIntegrations
    class UpdateService
      # @param integration [AlertManagement::HttpIntegration]
      # @param current_user [User]
      # @param params [Hash]
      def initialize(integration, current_user, params)
        @integration = integration
        @current_user = current_user
        @params = params
      end

      def execute
        return error_no_permissions unless allowed?

        params[:token] = nil if params.delete(:regenerate_token)

        if integration.update(params)
          success
        else
          error(integration.errors.full_messages.to_sentence)
        end
      end

      private

      attr_reader :integration, :current_user, :params

      def allowed?
        current_user&.can?(:admin_operations, integration)
      end

      def error(message)
        ServiceResponse.error(message: message)
      end

      def success
        ServiceResponse.success(payload: { integration: integration.reset })
      end

      def error_no_permissions
        error(_('You have insufficient permissions to update this HTTP integration'))
      end
    end
  end
end
