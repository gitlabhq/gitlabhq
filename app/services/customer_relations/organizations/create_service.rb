# frozen_string_literal: true

module CustomerRelations
  module Organizations
    class CreateService < BaseService
      # returns the created organization
      def execute
        return error_no_permissions unless allowed?

        organization = Organization.create(params.merge(group_id: group.id))

        return error_creating(organization) unless organization.persisted?

        ServiceResponse.success(payload: organization)
      end

      private

      def error_no_permissions
        error('You have insufficient permissions to create an organization for this group')
      end

      def error_creating(organization)
        error(organization&.errors&.full_messages || 'Failed to create organization')
      end
    end
  end
end
