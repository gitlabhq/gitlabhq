# frozen_string_literal: true

module Namespaces
  module ServiceAccounts
    class BaseUpdateService < ::Users::ServiceAccounts::UpdateService
      extend ::Gitlab::Utils::Override

      attr_reader :resource_id

      def initialize(current_user, user, params = {})
        super
        @resource_id = extract_resource_id(params)
      end

      override :execute
      def execute
        return error(error_messages[:resource_not_found], :not_found) unless resource.present?

        unless resource.id == user_provisioned_resource_id
          return error(error_messages[:invalid_resource_id], :bad_request)
        end

        super
      end

      private

      def extract_resource_id(_params)
        raise Gitlab::AbstractMethodError
      end

      def resource
        raise Gitlab::AbstractMethodError
      end

      def user_provisioned_resource_id
        raise Gitlab::AbstractMethodError
      end

      override :can_update_service_account?
      def can_update_service_account?
        return false unless user_provisioned_resource

        Ability.allowed?(current_user, :admin_service_accounts, user_provisioned_resource)
      end

      def user_provisioned_resource
        raise Gitlab::AbstractMethodError
      end

      override :error_messages
      def error_messages
        super.merge(
          no_permission:
            s_('ServiceAccount|You are not authorized to update service accounts in this namespace.'),
          invalid_resource_id: invalid_resource_id_message,
          resource_not_found: resource_not_found_message
        )
      end

      def invalid_resource_id_message
        raise Gitlab::AbstractMethodError
      end

      def resource_not_found_message
        raise Gitlab::AbstractMethodError
      end
    end
  end
end
