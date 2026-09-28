# frozen_string_literal: true

module Authn
  module Groups
    # Recalculates the cached `users.require_two_factor_authentication_from_group`
    # value for members of the group, its subgroups, and its ancestor groups.
    class UpdateTwoFactorRequirementService < ::BaseGroupService
      def execute
        recalculated_count = 0

        members.find_each do |member|
          recalculated_count += 1 if member.update_two_factor_requirement
        end

        ServiceResponse.success(payload: { recalculated_count: recalculated_count })
      end

      private

      def members
        ::GroupMember.active_for_self_and_hierarchy(group, minimal_access: include_minimal_access?)
      end

      # Temporary EE extension point: a follow-up MR removes this hook so the
      # Minimal Access decision lives only in the per-user recalculation.
      # https://gitlab.com/gitlab-org/gitlab/-/work_items/611322
      def include_minimal_access?
        false
      end
    end
  end
end

Authn::Groups::UpdateTwoFactorRequirementService.prepend_mod
