# frozen_string_literal: true

module AlertManagement
  module HttpIntegrations
    class UpdateService < BaseService
      # @param integration [AlertManagement::HttpIntegration]
      # @param current_user [User]
      # @param params [Hash]
      def initialize(integration, current_user, params)
        @integration = integration

        super(integration.project, current_user, params)
      end

      def execute
        return error_no_permissions unless allowed?

        integration.transaction do
          if integration.update(permitted_params.merge(token_params))
            @response = success(integration)

            if type_update? && too_many_integrations?(integration)
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

      attr_reader :integration

      def token_params
        return {} unless params[:regenerate_token]

        { token: nil }
      end

      def type_update?
        params[:type_identifier].present?
      end

      def error_no_permissions
        error(_('You have insufficient permissions to update this HTTP integration'))
      end
    end
  end
end
