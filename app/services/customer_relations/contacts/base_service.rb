# frozen_string_literal: true

module CustomerRelations
  module Contacts
    class BaseService < ::BaseGroupService
      private

      def allowed?
        current_user&.can?(:admin_crm_contact, group)
      end

      def error(message)
        ServiceResponse.error(message: Array(message))
      end

      def organization_valid?
        return true unless params[:organization_id]

        organization = Organization.find(params[:organization_id])
        organization.group_id == group.id
      rescue ActiveRecord::RecordNotFound
        false
      end

      def error_organization_invalid
        error('The specified organization was not found or does not belong to this group')
      end

      def error_no_permissions
        error('You have insufficient permissions to manage contacts for this group')
      end
    end
  end
end
