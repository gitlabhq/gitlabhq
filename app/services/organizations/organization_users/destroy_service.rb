# frozen_string_literal: true

module Organizations
  module OrganizationUsers
    class DestroyService
      include BaseServiceUtility

      def initialize(organization_user, current_user:)
        @organization_user = organization_user
        @current_user = current_user
      end

      def execute
        return denied_response unless allowed?
        return error_home_organization if home_organization?

        organization_user.destroy

        if organization_user.destroyed?
          ServiceResponse.success(payload: { organization_user: organization_user })
        else
          error_deleting
        end
      end

      private

      attr_reader :organization_user, :current_user

      def allowed?
        current_user&.can?(:delete_organization_user, organization_user)
      end

      def can_update_organization?
        current_user&.can?(:update_organization, organization_user.organization)
      end

      # Removing the user from their home organization would leave users.organization_id pointing at an
      # organization they are no longer a member of.
      def home_organization?
        organization_user.organization_id == organization_user.user.organization_id
      end

      # The delete_organization_user ability covers both authorization and the last owner rule, so we only
      # report the latter to users who are otherwise allowed to administer the organization.
      def denied_response
        return error_last_owner if can_update_organization? && organization_user.last_owner?

        error_no_permission
      end

      def error_no_permission
        ServiceResponse.error(
          message: [_('You have insufficient permissions to delete the organization user')],
          reason: :forbidden
        )
      end

      def error_last_owner
        ServiceResponse.error(
          message: [_('You cannot delete the last owner of the organization')],
          reason: :last_owner
        )
      end

      def error_home_organization
        ServiceResponse.error(
          message: [_('You cannot delete a user from their home organization')],
          reason: :home_organization
        )
      end

      def error_deleting
        message = organization_user.errors.full_messages
        message = _('Failed to delete the organization user') if message.empty?

        ServiceResponse.error(payload: { organization_user: organization_user }, message: Array(message))
      end
    end
  end
end
