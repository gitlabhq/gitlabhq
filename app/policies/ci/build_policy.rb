module Ci
  class BuildPolicy < CommitStatusPolicy
    condition(:protected_action) do
      next false unless @subject.action?

      access = ::Gitlab::UserAccess.new(@user, project: @subject.project)

      if @subject.tag?
        !access.can_create_tag?(@subject.ref)
      else
        !access.can_merge_to_branch?(@subject.ref)
      end
    end

    rule { protected_action }.prevent :update_build
  end
end
