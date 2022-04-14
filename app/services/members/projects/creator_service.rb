# frozen_string_literal: true

module Members
  module Projects
    class CreatorService < Members::CreatorService
      private

      def can_create_new_member?
        # order is important here!
        # The `admin_project_member` check has side-effects that causes projects not be created if this area is hit
        # during project creation.
        # Call that triggers is current_user.can?(:admin_project_member, member.project)
        # I tracked back to base_policy.rb admin check and specifically in
        # Gitlab::Auth::CurrentUserMode.new(@user).admin_mode? call.
        # This calls user.admin? and that specific call causes issues with project creation in
        # spec/requests/api/projects_spec.rb specs and others, mostly around project creation.
        # https://gitlab.com/gitlab-org/gitlab/-/issues/358931 for investigation
        adding_the_creator_as_owner_in_a_personal_project? || current_user.can?(:admin_project_member, member.project)
      end

      def can_update_existing_member?
        current_user.can?(:update_project_member, member)
      end

      def adding_the_creator_as_owner_in_a_personal_project?
        # this condition is reached during testing setup a lot due to use of `.add_user`
        member.project.personal_namespace_holder?(member.user)
      end
    end
  end
end
