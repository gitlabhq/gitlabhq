# frozen_string_literal: true

class IssuePolicy < IssuablePolicy
  # This class duplicates the same check of Issue#readable_by? for performance reasons
  # Make sure to sync this class checks with issue.rb to avoid security problems.
  # Check commit 002ad215818450d2cbbc5fa065850a953dc7ada8 for more information.

  include CrudPolicyHelpers

  # In FOSS there is no license.
  # This method is overridden in EE
  def epics_license_available?
    false
  end

  # Not available in FOSS.
  # This method is Overridden in EE
  def project_work_item_epics_available?
    false
  end

  # rubocop:disable Cop/UserAdmin -- specifically check the admin attribute
  desc "User can read confidential issues"
  condition(:can_read_confidential) do
    @user && (@user.admin? || planner_or_reporter_access? || assignee_or_author?)
  end
  # rubocop:enable Cop/UserAdmin

  desc "Project belongs to a group, crm is enabled and user can read contacts in source group"
  condition(:can_read_crm_contacts) do
    subject_container&.crm_enabled? &&
      (@user&.can?(:read_crm_contact, subject_container.crm_group) || @user&.support_bot?)
  end

  desc "Issue is confidential"
  condition(:confidential, scope: :subject) { @subject.confidential? }

  desc "Issue is persisted"
  condition(:persisted, scope: :subject) { @subject.persisted? }

  # accessing notes requires the notes widget to be available for work items(or issue)
  condition(:notes_widget_enabled, scope: :subject) do
    @subject.has_widget?(:notes)
  end

  condition(:group_issue, scope: :subject) { subject_container.is_a?(Group) }

  condition(:service_desk_enabled, scope: :subject) do
    if group_issue?
      subject_container.has_project_with_service_desk_enabled?
    else
      ::ServiceDesk.enabled?(subject_container)
    end
  end

  # this is temporarily needed until we rollout implementation of move and clone for all work item types
  condition(:supports_move_and_clone, scope: :subject) do
    @subject.supports_move_and_clone?
  end

  condition(:work_item_type_available, scope: :subject) do
    if group_issue?
      # For now all work item types at group-level require the epics licensed feature
      epics_license_available?
    elsif @subject.epic_work_item?
      project_work_item_epics_available?
    else
      true
    end
  end

  rule { group_issue & can?(:read_group) }.policy do
    enable :create_note
    enable :award_emoji
  end

  rule { ~notes_widget_enabled }.policy do
    prevent :create_note
    prevent :read_note
    prevent :admin_note
    prevent :read_internal_note
    prevent :set_note_created_at
    prevent :mark_note_as_internal
    # these actions on notes are not available on issues/work items yet,
    # but preventing any action on work item notes as long as there is no notes widget seems reasonable
    prevent :resolve_note
    prevent :reposition_note
  end

  rule { confidential & ~can_read_confidential }.policy do
    prevent(*create_read_update_admin_destroy(:issue))
    prevent(*create_read_update_admin_destroy(:work_item))
    prevent :read_issue_iid
  end

  rule { hidden & ~admin }.policy do
    prevent :read_issue
  end

  rule { can?(:read_issue) & notes_widget_enabled }.policy do
    enable :read_note
  end

  rule { can?(:maintainer_access) }.enable :admin_note

  rule { ~can?(:read_issue) }.policy do
    prevent :create_note
    prevent :read_note
    prevent :award_emoji
  end

  rule { locked }.policy do
    prevent :reopen_issue
  end

  rule { ~can?(:read_issue) }.policy do
    prevent :read_design
    prevent :create_design
    prevent :update_design
    prevent :destroy_design
    prevent :move_design
  end

  rule { ~anonymous & can?(:read_issue) }.policy do
    enable :create_todo
    enable :update_subscription
  end

  rule { can?(:admin_issue) }.policy do
    enable :set_issue_metadata
    enable :admin_issue_link
  end

  # guest members need to be able to set issue metadata per https://gitlab.com/gitlab-org/gitlab/-/issues/300100
  rule { ~persisted & is_project_member & can?(:guest_access) }.policy do
    enable :set_issue_metadata
  end

  rule { can?(:set_issue_metadata) }.policy do
    enable :set_confidentiality
  end

  rule { ~persisted & can?(:create_issue) }.policy do
    enable :set_confidentiality
  end

  rule { can?(:guest_access) & can?(:read_issue) }.policy do
    enable :admin_issue_relation
  end

  rule { can?(:guest_access) & can?(:read_issue) & is_project_member }.policy do
    enable :admin_issue_link
  end

  rule { support_bot & service_desk_enabled }.enable :admin_issue_relation

  rule { can_read_crm_contacts }.policy do
    enable :read_crm_contacts
  end

  rule { can?(:set_issue_metadata) & can_read_crm_contacts }.policy do
    enable :set_issue_crm_contacts
  end

  rule { planner_or_reporter_access }.policy do
    enable :mark_note_as_internal
  end

  rule { can?(:admin_issue) & supports_move_and_clone }.policy do
    enable :move_issue
    enable :clone_issue
  end

  rule { is_incident & ~can?(:reporter_access) }.policy do
    prevent :admin_issue
    prevent :update_issue
  end

  rule { is_incident & ~can?(:owner_access) }.policy do
    prevent :destroy_issue
  end

  # IMPORTANT: keep the prevention rules as last rules defined in the policy, as these are based on
  # all abilities defined up to this point.
  rule { ~work_item_type_available }.policy do
    prevent(*::IssuePolicy.ability_map.map.keys)
  end
end

IssuePolicy.prepend_mod_with('IssuePolicy')
