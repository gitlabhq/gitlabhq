# frozen_string_literal: true

# Worker for updating two factor requirement for all group members
module Groups
  class UpdateTwoFactorRequirementForMembersWorker
    include ApplicationWorker

    data_consistency :always

    idempotent!

    feature_category :authentication_and_authorization

    def perform(group_id)
      group = Group.find_by_id(group_id)

      return unless group

      group.update_two_factor_requirement_for_members
    end
  end
end
