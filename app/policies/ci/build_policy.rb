module Ci
  class BuildPolicy < CommitStatusPolicy
    condition(:user_cannot_update) do
      access = ::Gitlab::UserAccess.new(@user, project: @subject.project)

      if @subject.tag?
        !access.can_create_tag?(@subject.ref)
      else
        !access.can_update_branch?(@subject.ref)
      end
    end

    rule { user_cannot_update }.prevent :update_build
  end
end
