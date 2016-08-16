class ProjectSnippetPolicy < BasePolicy
  def rules
    can! :read_project_snippet if @subject.public?
    return unless @user

    if @user && @subject.author == @user || @user.admin?
      can! :read_project_snippet
      can! :update_project_snippet
      can! :admin_project_snippet
    end

    if @subject.internal? && !@user.external?
      can! :read_project_snippet
    end

    if @subject.private? && @subject.project.team.member?(@user)
      can! :read_project_snippet
    end
  end
end
