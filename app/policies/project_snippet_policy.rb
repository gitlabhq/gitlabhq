class ProjectSnippetPolicy < BasePolicy
  delegate { @subject.project }
  desc "Snippet is public"
  condition(:public_snippet, scope: :subject) { @subject.public? }

  condition(:is_author) { @user && @subject.author == @user }

  condition(:internal, scope: :subject) { @subject.internal? }

  # We have to check both project feature visibility and a snippet visibility and take the stricter one
  # This will be simplified - check https://gitlab.com/gitlab-org/gitlab-ce/issues/27573
  rule { ~can?(:read_project) }.prevent_all
  rule { snippets_disabled }.prevent_all

  rule { internal & ~external_user }.enable :read_project_snippet

  rule { public_snippet }.enable :read_project_snippet

  rule { is_author | admin }.policy do
    enable :read_project_snippet
    enable :update_project_snippet
    enable :admin_project_snippet
  end

  rule { team_member }.enable :read_project_snippet
end
