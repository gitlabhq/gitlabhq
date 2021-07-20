# frozen_string_literal: true

module Members
  module Projects
    class CreatorService < Members::CreatorService
      def self.access_levels
        Gitlab::Access.sym_options
      end

      private

      def can_update_member?
        super || current_user.can?(:update_project_member, member) || adding_a_new_owner?
      end

      def adding_a_new_owner?
        # this condition is reached during testing setup a lot due to use of `.add_user`
        member.owner? && member.new_record?
      end
    end
  end
end
