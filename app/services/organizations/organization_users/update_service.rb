# frozen_string_literal: true

module Organizations
  module OrganizationUsers
    class UpdateService
      include BaseServiceUtility

      def initialize(organization_user, current_user:, params: {})
        @organization_user = organization_user
        @current_user = current_user
        @params = params.dup
      end

      def execute
        return error_response unless allowed?

        if organization_user.update(params)
          ServiceResponse.success(payload: { organization_user: organization_user })
        else
          error_updating
        end
      end

      private

      attr_reader :organization_user, :current_user, :params

      def allowed?
        current_user&.can?(:admin_organization, organization_user.organization)
      end

      def error_response
        ServiceResponse.error(message: [_('You have insufficient permissions to update the organization user')])
      end

      def error_updating
        message = organization_user.errors.full_messages
        message = _('Failed to update the organization user') if message.empty?

        ServiceResponse.error(payload: { organization_user: organization_user }, message: Array(message))
      end
    end
  end
end
