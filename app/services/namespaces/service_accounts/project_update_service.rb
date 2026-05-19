# frozen_string_literal: true

module Namespaces
  module ServiceAccounts
    class ProjectUpdateService < BaseUpdateService
      extend ::Gitlab::Utils::Override

      private

      override :extract_resource_id
      def extract_resource_id(params)
        params[:project_id]
      end

      override :resource
      def resource
        @_resource ||= ::Project.find_by_id(@resource_id)
      end

      override :user_provisioned_resource_id
      def user_provisioned_resource_id
        user.provisioned_by_project_id
      end

      override :user_provisioned_resource
      def user_provisioned_resource
        user.provisioned_by_project
      end

      override :invalid_resource_id_message
      def invalid_resource_id_message
        s_("ServiceAccount|Project ID provided does not match the service account's project ID.")
      end

      override :resource_not_found_message
      def resource_not_found_message
        s_('ServiceAccount|Project with the provided ID not found.')
      end
    end
  end
end
