class ProjectSnippetPolicy < BasePolicy
  delegate :project

  desc "Snippet is public"
  condition(:public_snippet, scope: :subject) { @subject.public? }
  condition(:private_snippet, scope: :subject) { @subject.private? }
  condition(:public_project, scope: :subject) { @subject.project.public? }

  condition(:is_author) { @user && @subject.author == @user }

  condition(:internal, scope: :subject) { @subject.internal? }

  # We have to check both project feature visibility and a snippet visibility and take the stricter one
  # This will be simplified - check https://gitlab.com/gitlab-org/gitlab-ce/issues/27573
  rule { ~can?(:read_project) }.policy do
    prevent :read_project_snippet
    prevent :update_project_snippet
    prevent :admin_project_snippet
  end

  # we have to use this complicated prevent because the delegated project policy
  # is overly greedy in allowing :read_project_snippet, since it doesn't have any
  # information about the snippet. However, :read_project_snippet on the *project*
  # is used to hide/show various snippet-related controls, so we can't just move
  # all of the handling here.
  rule do
    all?(private_snippet | (internal & external_user),
         ~project.guest,
         ~admin,
         ~is_author)
  end.prevent :read_project_snippet

  rule { internal & ~is_author & ~admin }.policy do
    prevent :update_project_snippet
    prevent :admin_project_snippet
  end

  rule { public_snippet }.enable :read_project_snippet

  rule { is_author | admin }.policy do
    enable :read_project_snippet
    enable :update_project_snippet
    enable :admin_project_snippet
  end
end
