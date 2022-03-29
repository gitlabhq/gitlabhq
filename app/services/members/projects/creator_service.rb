# frozen_string_literal: true

module Members
  module Projects
    class CreatorService < Members::CreatorService
      def self.access_levels
        Gitlab::Access.sym_options_with_owner
      end

      private

      def can_update_member?
        super || current_user.can?(:update_project_member, member) || adding_the_creator_as_owner_in_a_personal_project?
      end

      def adding_the_creator_as_owner_in_a_personal_project?
        # this condition is reached during testing setup a lot due to use of `.add_user`
        member.project.personal_namespace_holder?(member.user) && member.new_record?
      end
    end
  end
end
