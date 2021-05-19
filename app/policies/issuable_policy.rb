# frozen_string_literal: true

class IssuablePolicy < BasePolicy
  delegate { @subject.project }

  condition(:locked, scope: :subject, score: 0) { @subject.discussion_locked? }
  condition(:is_project_member) { @user && @subject.project && @subject.project.team.member?(@user) }

  desc "User is the assignee or author"
  condition(:assignee_or_author) do
    @user && @subject.assignee_or_author?(@user)
  end

  rule { can?(:guest_access) & assignee_or_author }.policy do
    enable :read_issue
    enable :update_issue
    enable :reopen_issue
    enable :read_merge_request
    enable :update_merge_request
    enable :reopen_merge_request
  end

  rule { locked & ~is_project_member }.policy do
    prevent :create_note
    prevent :admin_note
    prevent :resolve_note
    prevent :award_emoji
  end
end

IssuablePolicy.prepend_mod_with('IssuablePolicy')
