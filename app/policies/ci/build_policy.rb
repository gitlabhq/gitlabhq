module Ci
  class BuildPolicy < CommitStatusPolicy
    condition(:protected_action) do
      next false unless @subject.action?

      access = ::Gitlab::UserAccess.new(@user, project: @subject.project)

      !access.can_merge_to_branch?(@subject.ref) ||
        !access.can_create_tag?(@subject.ref)
    end

    rule { protected_action }.prevent :update_build
  end
end
