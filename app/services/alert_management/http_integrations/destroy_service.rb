# frozen_string_literal: true

module AlertManagement
  module HttpIntegrations
    class DestroyService
      # @param integration [AlertManagement::HttpIntegration]
      # @param current_user [User]
      def initialize(integration, current_user)
        @integration = integration
        @current_user = current_user
      end

      def execute
        return error_no_permissions unless allowed?
        return error_legacy_prometheus unless destroy_allowed?

        if integration.destroy
          success
        else
          error(integration.errors.full_messages.to_sentence)
        end
      end

      private

      attr_reader :integration, :current_user

      def allowed?
        current_user&.can?(:admin_operations, integration)
      end

      # Prevents downtime while migrating from Integrations::Prometheus.
      # Remove with https://gitlab.com/gitlab-org/gitlab/-/issues/409734
      def destroy_allowed?
        !(integration.legacy? && integration.prometheus?)
      end

      def error(message)
        ServiceResponse.error(message: message)
      end

      def success
        ServiceResponse.success(payload: { integration: integration })
      end

      def error_no_permissions
        error(_('You have insufficient permissions to remove this HTTP integration'))
      end

      def error_legacy_prometheus
        error(_('Legacy Prometheus integrations cannot currently be removed'))
      end
    end
  end
end
