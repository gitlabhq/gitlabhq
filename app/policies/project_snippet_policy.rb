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
  condition(:private_to_user) do
    private_snippet? || (internal_snippet? && external_user?)
  end

  rule { ~is_author }.policy do
    prevent :_admin_authored_snippet
    prevent :_read_authored_snippet
    prevent :_update_authored_snippet
  end

  rule { private_to_user & ~can?(:_read_private_snippet) }.prevent :read_snippet

  rule { can?(:_read_authored_snippet) }.enable :_read_private_snippet
  rule { can?(:_update_authored_snippet) }.enable :update_snippet
  rule { can?(:_admin_authored_snippet) }.enable :admin_snippet

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
