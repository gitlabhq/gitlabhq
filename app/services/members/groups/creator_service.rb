# frozen_string_literal: true

module Members
  module Groups
    class CreatorService < Members::CreatorService
      class << self
        def cannot_manage_owners?(source, current_user)
          source.max_member_access_for_user(current_user) < Gitlab::Access::OWNER
        end
      end

      private

      def can_create_new_member?
        current_user.can?(:admin_group_member, member.group)
      end

      def can_update_existing_member?
        current_user.can?(:update_group_member, member)
      end
    end
  end
end

Members::Groups::CreatorService.prepend_mod_with('Members::Groups::CreatorService')
