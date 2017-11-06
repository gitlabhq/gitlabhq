module Ci
  class BuildPolicy < CommitStatusPolicy
    condition(:protected_ref) do
      access = ::Gitlab::UserAccess.new(@user, project: @subject.project)

      if @subject.tag?
        !access.can_create_tag?(@subject.ref)
      else
        !access.can_update_branch?(@subject.ref)
      end
    end

    condition(:owner_of_build) do
      can?(:developer_access) && @subject.owned_by?(@user)
    end

    rule { protected_ref }.prevent :update_build
    rule { can?(:master_access) | owner_of_build }.enable :erase_build
  end
end
