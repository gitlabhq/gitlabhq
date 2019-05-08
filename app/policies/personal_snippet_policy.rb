# frozen_string_literal: true

class PersonalSnippetPolicy < BasePolicy
  condition(:public_snippet, scope: :subject) { @subject.public? }
  condition(:is_author) { @user && @subject.author == @user }
  condition(:internal_snippet, scope: :subject) { @subject.internal? }

  rule { public_snippet }.policy do
    enable :read_personal_snippet
    enable :create_note
  end

  rule { is_author }.policy do
    enable :read_personal_snippet
    enable :update_personal_snippet
    enable :destroy_personal_snippet
    enable :admin_personal_snippet
    enable :create_note
  end

  rule { ~anonymous }.enable :create_personal_snippet
  rule { external_user }.prevent :create_personal_snippet

  rule { internal_snippet & ~external_user }.policy do
    enable :read_personal_snippet
    enable :create_note
  end

  rule { anonymous }.prevent :create_note

  rule { can?(:create_note) }.enable :award_emoji

  rule { full_private_access }.enable :read_personal_snippet
end
