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

    rule { protected_ref }.prevent :update_build
  end
end
