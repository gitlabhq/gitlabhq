# frozen_string_literal: true

module Members
  module Projects
    class CreatorService < Members::CreatorService
      class << self
        def cannot_manage_owners?(source, current_user)
          !Ability.allowed?(current_user, :manage_owners, source)
        end
      end

      private

      def can_create_new_member?
        return false if assigning_project_member_with_owner_access_level? &&
          cannot_assign_owner_responsibilities_to_member_in_project?

        # This access check(`admin_project_member`) will write to safe request store cache for the user being added.
        # This means any operations inside the same request will need to purge that safe request
        # store cache if operations are needed to be done inside the same request that checks max member access again on
        # that user.
        current_user.can?(:admin_project_member, member.project) || adding_the_creator_as_owner_in_a_personal_project?
      end

      def can_update_existing_member?
        raise ::Gitlab::Access::AccessDeniedError if assigning_project_member_with_owner_access_level? &&
          cannot_assign_owner_responsibilities_to_member_in_project?

        current_user.can?(:update_project_member, member)
      end

      def adding_the_creator_as_owner_in_a_personal_project?
        # this condition is reached during testing setup a lot due to use of `.add_member`
        member.project.personal_namespace_holder?(member.user)
      end

      def assigning_project_member_with_owner_access_level?
        return true if member && member.owner?

        access_level == Gitlab::Access::OWNER
      end

      def cannot_assign_owner_responsibilities_to_member_in_project?
        member.is_a?(ProjectMember) && !current_user.can?(:manage_owners, member.source)
      end
    end
  end
end
