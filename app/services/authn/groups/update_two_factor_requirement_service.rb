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
        ::GroupMember.active_for_self_and_hierarchy(group, minimal_access: true)
      end
    end
  end
end
