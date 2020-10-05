# frozen_string_literal: true

module InviteMembersHelper
  def invite_members_allowed?(group)
    Feature.enabled?(:invite_members_group_modal, group) && can?(current_user, :admin_group_member, group)
  end
end
