# frozen_string_literal: true

class ProjectMemberPolicy < BasePolicy
  include MemberPolicyHelpers
  delegate { @subject.project }

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

  rule { ~project_bot & can?(:admin_project_member) }.policy do
    enable :update_project_member
    enable :destroy_project_member
  end

  rule { project_bot & can?(:admin_project_member) }.enable :destroy_project_bot_member

  rule { target_is_self }.policy do
    enable :destroy_project_member
  end

  rule { access_request_of_self }.policy do
    enable :withdraw_member_access_request
  end
end

ProjectMemberPolicy.prepend_mod_with('ProjectMemberPolicy')
