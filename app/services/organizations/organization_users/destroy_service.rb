# frozen_string_literal: true

module Organizations
  module OrganizationUsers
    class DestroyService
      include BaseServiceUtility

      MembershipRemovalError = Class.new(StandardError)

      def initialize(organization_user, current_user:)
        @organization_user = organization_user
        @current_user = current_user
      end

      def execute
        return denied_response unless allowed?

        removed_count = remove_memberships
        organization_user.destroy!

        log_removal(removed_count)
        ServiceResponse.success(payload: { organization_user: organization_user })
      rescue MembershipRemovalError
        error_membership_removal_failed
      rescue ActiveRecord::RecordNotDestroyed
        error_deleting
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

      def remove_memberships
        members = Member
          .with_user(organization_user.user)
          .non_request
          .in_organization(organization_user.organization_id)
          .to_a

        members.each do |member|
          ::Members::DestroyService.new(
            member,
            current_user: current_user,
            skip_authorization: true,
            skip_subresources: true,
            unassign_issuables: true
          ).execute

          raise MembershipRemovalError unless member.destroyed?
        end

        members.size
      end

      def log_removal(removed_count)
        Gitlab::AppLogger.info(
          message: 'Removed user from organization and cascaded membership removal',
          Labkit::Fields::GL_ORGANIZATION_ID => organization_user.organization_id,
          target_user_id: organization_user.user_id,
          current_user_id: current_user.id,
          removed_memberships_count: removed_count
        )
      end

      # The delete_organization_user ability covers both authorization and the last owner rule, so we only
      # report the latter to users who are otherwise allowed to administer the organization.
      def denied_response
        return error_home_organization if home_organization?
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

      def error_membership_removal_failed
        ServiceResponse.error(
          message: [_('Failed to remove the user from groups or projects in the organization')],
          reason: :membership_removal_failed
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

Organizations::OrganizationUsers::DestroyService.prepend_mod
