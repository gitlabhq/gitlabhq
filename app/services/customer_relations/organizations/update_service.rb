# frozen_string_literal: true

module CustomerRelations
  module Organizations
    class UpdateService < BaseService
      def execute(organization)
        return error_no_permissions unless allowed?
        return error_updating(organization) unless organization.update(params)

        ServiceResponse.success(payload: organization)
      end

      private

      def error_no_permissions
        error('You have insufficient permissions to update an organization for this group')
      end

      def error_updating(organization)
        error(organization&.errors&.full_messages || 'Failed to update organization')
      end
    end
  end
end
