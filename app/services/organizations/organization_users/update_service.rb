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
          sync_organization_admin_role
          ServiceResponse.success(payload: { organization_user: organization_user })
        else
          error_updating
        end
      end

      private

      attr_reader :organization_user, :current_user, :params

      # access_level currently has exactly two values (default/owner), so any
      # saved change is necessarily a transition across the owner boundary.
      # Revisit this if a third access_level is ever introduced.
      def sync_organization_admin_role
        return unless organization_user.saved_change_to_access_level?
        return unless ::Authz::Organizations::OwnerRoleSync.enabled?

        worker = if organization_user.owner?
                   ::Authz::Organizations::GrantOwnerRoleWorker
                 else
                   ::Authz::Organizations::RevokeOwnerRoleWorker
                 end

        worker.perform_async(organization_user.organization_id, organization_user.user_id, current_user.id)
      end

      def allowed?
        current_user&.can?(:update_organization, organization_user.organization)
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
