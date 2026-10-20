# frozen_string_literal: true

class ProjectMemberPolicy < BasePolicy
  include MemberPolicyHelpers

  delegate { @subject.project }

  overrides(:destroy_project_member)

  condition(:target_is_holder_of_the_personal_namespace, scope: :subject) do
    @subject.holder_of_the_personal_namespace?
  end

  desc "Membership is users' own access request"
  with_score 0
  condition(:access_request_of_self) { record_is_access_request_of_self? }

  condition(:target_is_self) { record_belongs_to_self? }
  condition(:project_bot) { @subject.user&.project_bot? }

  rule { anonymous }.prevent_all

  rule { target_is_holder_of_the_personal_namespace }.policy do
    prevent :update_project_member
    prevent :destroy_project_member
  end

  # Not gated on admin_project_member, which read-only (archived or pending deletion) projects
  # prevent: they block adding members, but removing them must keep working.
  condition(:can_remove_project_members) do
    can?(:destroy_project_member, @subject.project)
  end

  rule { ~project_bot & can?(:admin_project_member) }.enable :update_project_member

  rule { ~project_bot & can_remove_project_members }.enable :destroy_project_member

  rule { project_bot & can_remove_project_members }.enable :destroy_project_bot_member

  rule { target_is_self }.policy do
    enable :destroy_project_member
  end

  rule { access_request_of_self }.policy do
    enable :withdraw_member_access_request
  end
end

ProjectMemberPolicy.prepend_mod_with('ProjectMemberPolicy')
