# frozen_string_literal: true

class IssuablePolicy < BasePolicy
  delegate { subject_container }

  condition(:locked, scope: :subject, score: 0) { @subject.discussion_locked? }
  condition(:is_project_member) { subject_container.member?(@user) }
  condition(:can_read_issuable) { can?(:"read_#{@subject.to_ability_name}") }

  desc "User is the assignee or author"
  condition(:assignee_or_author) do
    @user && @subject.assignee_or_author?(@user)
  end

  desc "User has planner or reporter access"
  condition(:planner_or_reporter_access) do
    can?(:reporter_access) || can?(:planner_access)
  end

  condition(:is_author) { @subject&.author == @user }

  condition(:is_incident) { @subject.incident_type_issue? }

  desc "Issuable is hidden"
  condition(:hidden, scope: :subject) { @subject.hidden? }

  rule { can?(:developer_access) }.policy do
    enable :resolve_note
  end

  rule { can?(:guest_access) & assignee_or_author & ~is_incident }.policy do
    enable :read_issue
    enable :update_issue
    enable :reopen_issue
  end

  rule { can?(:read_merge_request) & assignee_or_author }.policy do
    enable :update_merge_request
    enable :reopen_merge_request
  end

  rule { is_author }.policy do
    enable :resolve_note
  end

  rule { locked & ~is_project_member }.policy do
    prevent :create_note
    prevent :admin_note
    prevent :resolve_note
    prevent :award_emoji
  end

  rule { can?(:read_issue) }.policy do
    enable :read_incident_management_timeline_event
  end

  rule { can?(:read_issue) & can?(:developer_access) }.policy do
    enable :admin_incident_management_timeline_event
  end

  rule { planner_or_reporter_access }.policy do
    enable :create_timelog
  end

  rule { can_read_issuable }.policy do
    enable :read_issuable
    enable :read_issuable_participables
  end

  def subject_container
    @subject.project || @subject.try(:namespace)
  end
end

IssuablePolicy.prepend_mod_with('IssuablePolicy')
