class ProjectSnippetPolicy < BasePolicy
  def rules
    # We have to check both project feature visibility and a snippet visibility and take the stricter one
    # This will be simplified - check https://gitlab.com/gitlab-org/gitlab-ce/issues/27573
    return unless @subject.project.feature_available?(:snippets, @user)
    return unless Ability.allowed?(@user, :read_project, @subject.project)

    can! :read_project_snippet if @subject.public?
    return unless @user

    if @user && (@subject.author == @user || @user.admin?)
      can! :read_project_snippet
      can! :update_project_snippet
      can! :admin_project_snippet
    end

    if @subject.internal? && !@user.external?
      can! :read_project_snippet
    end

    if @subject.project.team.member?(@user)
      can! :read_project_snippet
    end
  end
end
