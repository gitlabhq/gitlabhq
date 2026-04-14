# frozen_string_literal: true

class IssuablePolicy < BasePolicy
  delegate { subject_container }

  condition(:locked, scope: :subject, score: 0) { @subject.discussion_locked? }
  condition(:is_container_member) { subject_container.member?(@user) }
  condition(:can_read_issuable) { can?(:"read_#{@subject.to_ability_name}") }

  desc "User is the assignee or author"
  condition(:assignee_or_author) do
    @user && @subject.assignee_or_author?(@user)
  end

  condition(:is_author) { @subject.author == @user }
  condition(:is_assignee) { @user && @subject.assignee?(@user) }

  condition(:is_incident) { @subject.incident_type_issue? }

  desc "Issuable is hidden"
  condition(:hidden, scope: :subject) { @subject.hidden? }

  rule { is_incident }.policy do
    prevent :_read_assigned_work_item
    prevent :_read_authored_work_item

    prevent :_reopen_assigned_work_item
    prevent :_reopen_authored_work_item

    prevent :_update_assigned_work_item
    prevent :_update_authored_work_item
  end

  rule { can?(:_read_assigned_work_item) & is_assignee }.enable :read_issue
  rule { can?(:_read_authored_work_item) & is_author }.enable :read_issue

  rule { can?(:_update_assigned_work_item) & is_assignee }.enable :update_issue
  rule { can?(:_update_authored_work_item) & is_author }.enable :update_issue

  rule { can?(:_reopen_assigned_work_item) & is_assignee }.enable :reopen_issue
  rule { can?(:_reopen_authored_work_item) & is_author }.enable :reopen_issue

  rule { can?(:read_merge_request) & assignee_or_author }.policy do
    enable :update_merge_request
    enable :reopen_merge_request
  end

  rule { locked & ~is_container_member }.policy do
    prevent :create_note
    prevent :admin_note
    prevent :award_emoji
  end

  rule { can?(:read_issue) }.policy do
    enable :read_incident_management_timeline_event
  end

  rule { ~can_read_issuable }.policy do
    prevent :create_timelog
    prevent :admin_incident_management_timeline_event
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
