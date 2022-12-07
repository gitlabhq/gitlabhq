# frozen_string_literal: true

class GroupMemberPolicy < BasePolicy
  include MemberPolicyHelpers

  delegate :group

  with_scope :subject
  condition(:last_owner) { @subject.last_owner_of_the_group? }
  condition(:project_bot) { @subject.user&.project_bot? && @subject.group.member?(@subject.user) }

  desc "Membership is users' own"
  with_score 0
  condition(:target_is_self) { record_belongs_to_self? }

  desc "Membership is users' own access request"
  with_score 0
  condition(:access_request_of_self) { record_is_access_request_of_self? }

  rule { anonymous }.policy do
    prevent :update_group_member
    prevent :destroy_group_member
  end

  rule { last_owner }.policy do
    prevent :update_group_member
    prevent :destroy_group_member
  end

  rule { ~project_bot & can?(:admin_group_member) }.policy do
    enable :update_group_member
    enable :destroy_group_member
  end

  rule { project_bot & can?(:admin_group_member) }.enable :destroy_project_bot_member

  rule { target_is_self }.policy do
    enable :destroy_group_member
  end

  rule { access_request_of_self }.policy do
    enable :withdraw_member_access_request
  end
end

GroupMemberPolicy.prepend_mod_with('GroupMemberPolicy')
