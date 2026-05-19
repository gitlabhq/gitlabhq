# frozen_string_literal: true

module Members
  module Groups
    class CreatorService < Members::CreatorService
      include Gitlab::Utils::StrongMemoize

      private

      def can_create_new_member?
        return false unless service_account_eligible_for_membership?

        current_user.can?(:admin_group_member, member.group)
      end

      def can_update_existing_member?
        current_user.can?(:update_group_member, member)
      end

      def service_account_eligible_for_membership?
        return true unless member.user&.service_account?

        ::Members::ServiceAccounts::EligibilityChecker.new(target_group: member.group).eligible?(member.user)
      end
      strong_memoize_attr :service_account_eligible_for_membership?
    end
  end
end

Members::Groups::CreatorService.prepend_mod_with('Members::Groups::CreatorService')
