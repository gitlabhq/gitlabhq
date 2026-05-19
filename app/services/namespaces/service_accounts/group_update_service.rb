# frozen_string_literal: true

module Namespaces
  module ServiceAccounts
    class GroupUpdateService < BaseUpdateService
      extend ::Gitlab::Utils::Override

      private

      override :extract_resource_id
      def extract_resource_id(params)
        params[:group_id]
      end

      override :resource
      def resource
        @_resource ||= ::Group.find_by_id(@resource_id)
      end

      override :user_provisioned_resource_id
      def user_provisioned_resource_id
        user.provisioned_by_group_id
      end

      override :user_provisioned_resource
      def user_provisioned_resource
        user.provisioned_by_group
      end

      override :skip_confirmation?
      def skip_confirmation?
        return true if super

        resource.owner_of_email?(params[:email])
      end

      override :invalid_resource_id_message
      def invalid_resource_id_message
        s_("ServiceAccount|Group ID provided does not match the service account's group ID.")
      end

      override :resource_not_found_message
      def resource_not_found_message
        s_('ServiceAccount|Group with the provided ID not found.')
      end
    end
  end
end
