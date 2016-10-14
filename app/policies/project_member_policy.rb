class ProjectMemberPolicy < BasePolicy
  def rules
    # anonymous users have no abilities here
    return unless @user

    target_user = @subject.user
    project = @subject.project

    return if target_user == project.owner

    can_manage = Ability.allowed?(@user, :admin_project_member, project)

    if can_manage
      can! :update_project_member
      can! :destroy_project_member
    end

    if @user == target_user
      can! :destroy_project_member
    end
  end
end
