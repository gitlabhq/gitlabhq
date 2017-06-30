module Ci
  class BuildPolicy < CommitStatusPolicy
    condition(:protected_action) do
      next false unless @subject.action?

      !::Gitlab::UserAccess
        .new(@user, project: @subject.project)
        .can_merge_to_branch?(@subject.ref)
    end

    rule { protected_action }.prevent :update_build
  end
end
