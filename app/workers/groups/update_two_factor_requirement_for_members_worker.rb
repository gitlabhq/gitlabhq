# frozen_string_literal: true

# Worker for updating two factor requirement for all group members
module Groups
  class UpdateTwoFactorRequirementForMembersWorker
    include ApplicationWorker

    data_consistency :always

    idempotent!

    feature_category :system_access

    def perform(group_id)
      group = Group.find_by_id(group_id)

      return unless group

      ::Authn::Groups::UpdateTwoFactorRequirementService.new(group: group).execute
    end
  end
end
