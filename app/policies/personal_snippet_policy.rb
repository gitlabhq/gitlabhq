# frozen_string_literal: true

class PersonalSnippetPolicy < BasePolicy
  condition(:public_snippet, scope: :subject) { @subject.public? }
  condition(:is_author) { @user && @subject.author == @user }
  condition(:internal_snippet, scope: :subject) { @subject.internal? }
  condition(:hidden, scope: :subject) { @subject.hidden_due_to_author_ban? }

  rule { public_snippet }.policy do
    enable :read_snippet
    enable :read_note
    enable :create_note
    enable :cache_blob
  end

  rule { is_author | admin }.policy do
    enable :read_snippet
    enable :update_snippet
    enable :admin_snippet
    enable :read_note
    enable :create_note
  end

  rule { internal_snippet & ~external_user }.policy do
    enable :read_snippet
    enable :read_note
    enable :create_note
  end

  rule { anonymous }.prevent :create_note

  rule { can?(:create_note) }.enable :award_emoji

  rule { hidden & ~can?(:read_all_resources) }.policy do
    prevent :read_snippet
    prevent :update_snippet
    prevent :admin_snippet
    prevent :read_note
    prevent :create_note
  end

  rule { can?(:read_all_resources) }.enable :read_snippet
end
