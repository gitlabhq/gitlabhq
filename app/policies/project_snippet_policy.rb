# frozen_string_literal: true

class ProjectSnippetPolicy < BasePolicy
  delegate :project

  desc "Snippet is public"
  condition(:public_snippet, scope: :subject) { @subject.public? }
  condition(:internal_snippet, scope: :subject) { @subject.internal? }
  condition(:private_snippet, scope: :subject) { @subject.private? }
  condition(:public_project, scope: :subject) { @subject.project.public? }
  condition(:hidden, scope: :subject) { @subject.hidden_due_to_author_ban? }
  condition(:is_author) { @user && @subject.author == @user }

  # We have to check both project feature visibility and a snippet visibility and take the stricter one
  # This will be simplified - check https://gitlab.com/gitlab-org/gitlab-foss/issues/27573
  rule { ~can?(:read_project) }.policy do
    prevent :read_snippet
    prevent :update_snippet
    prevent :admin_snippet
  end

  # we have to use this complicated prevent because the delegated project
  # policy is overly greedy in allowing :read_snippet, since it doesn't have
  # any information about the snippet. However, :read_snippet on the *project*
  # is used to hide/show various snippet-related controls, so we can't just
  # move all of the handling here.
  rule do
    all?(
      private_snippet | (internal_snippet & external_user),
      ~project.guest,
      ~is_author,
      ~can?(:read_all_resources)
    )
  end.prevent :read_snippet

  rule { internal_snippet & ~is_author & ~admin & ~project.maintainer }.policy do
    prevent :update_snippet
    prevent :admin_snippet
  end

  rule { public_snippet }.enable :read_snippet

  rule { is_author & ~project.reporter & ~admin }.policy do
    prevent :admin_snippet
  end

  rule { is_author | admin | project.maintainer }.policy do
    enable :read_snippet
    enable :update_snippet
    enable :admin_snippet
  end

  rule { hidden & ~can?(:read_all_resources) }.policy do
    prevent :read_snippet
    prevent :update_snippet
    prevent :admin_snippet
    prevent :read_note
  end

  rule { ~can?(:read_snippet) }.prevent :create_note

  rule { public_snippet & public_project }.enable :cache_blob
end

ProjectSnippetPolicy.prepend_mod_with('ProjectSnippetPolicy')
