# frozen_string_literal: true

module Members
  module Projects
    class CreatorService < Members::CreatorService
      private

      def can_create_new_member?
        # This access check(`admin_project_member`) will write to safe request store cache for the user being added.
        # This means any operations inside the same request will need to purge that safe request
        # store cache if operations are needed to be done inside the same request that checks max member access again on
        # that user.
        current_user.can?(:admin_project_member, member.project) || adding_the_creator_as_owner_in_a_personal_project?
      end

      def can_update_existing_member?
        current_user.can?(:update_project_member, member)
      end

      def adding_the_creator_as_owner_in_a_personal_project?
        # this condition is reached during testing setup a lot due to use of `.add_member`
        member.project.personal_namespace_holder?(member.user)
      end
    end
  end
end

Members::Projects::CreatorService.prepend_mod_with('Members::Projects::CreatorService')
