# frozen_string_literal: true

module CustomerRelations
  module Organizations
    class CreateService < ::BaseGroupService
      # returns the created organization
      def execute
        return error_no_permissions unless allowed?

        params[:group_id] = group.id

        organization = Organization.create(params)

        return error_creating(organization) unless organization.persisted?

        ServiceResponse.success(payload: organization)
      end

      private

      def allowed?
        current_user&.can?(:admin_organization, group)
      end

      def error(message)
        ServiceResponse.error(message: message)
      end

      def error_no_permissions
        error('You have insufficient permissions to create an organization for this group')
      end

      def error_creating(organization)
        error(organization&.errors&.full_messages || 'Failed to create organization')
      end
    end
  end
end
