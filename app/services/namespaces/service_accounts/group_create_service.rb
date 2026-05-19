# frozen_string_literal: true

module Namespaces
  module ServiceAccounts
    class GroupCreateService < BaseCreateService
      extend ::Gitlab::Utils::Override

      private

      override :resource
      def resource
        ::Group.find_by_id(params[:namespace_id])
      end
      strong_memoize_attr :resource

      override :resource_type
      def resource_type
        'group'
      end

      override :provisioning_params
      def provisioning_params
        {
          group_id: resource.id,
          provisioned_by_group_id: resource.id
        }
      end

      override :skip_owner_check?
      def skip_owner_check?
        # Allow service account creation for AI catalog items when the user has
        # :admin_ai_catalog_item_consumer permission. This enables maintainers/developers
        # to enable foundational flows without requiring group owner privileges.
        params[:skip_owner_check] == true && params[:composite_identity_enforced] == true
      end
    end
  end
end
