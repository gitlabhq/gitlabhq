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

    condition(:owner_of_job) do
      can?(:developer_access) && @subject.triggered_by?(@user)
    end

    rule { protected_ref }.policy do
      prevent :update_build
      prevent :erase_build
    end

    rule { can?(:master_access) | owner_of_job }.enable :erase_build
  end
end
