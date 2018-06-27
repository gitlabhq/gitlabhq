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
      @subject.triggered_by?(@user)
    end

    condition(:branch_allows_collaboration) do
      @subject.project.branch_allows_collaboration?(@user, @subject.ref)
    end

    rule { protected_ref }.policy do
      prevent :update_build
      prevent :erase_build
    end

    rule { can?(:admin_build) | (can?(:update_build) & owner_of_job) }.enable :erase_build

    rule { can?(:public_access) & branch_allows_collaboration }.policy do
      enable :update_build
      enable :update_commit_status
    end
  end
end
