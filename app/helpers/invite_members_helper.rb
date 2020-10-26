# frozen_string_literal: true

module InviteMembersHelper
  include Gitlab::Utils::StrongMemoize

  def invite_members_allowed?(group)
    Feature.enabled?(:invite_members_group_modal, group) && can?(current_user, :admin_group_member, group)
  end

  def directly_invite_members?
    strong_memoize(:directly_invite_members) do
      experiment_enabled?(:invite_members_version_a) && can_import_members?
    end
  end

  def indirectly_invite_members?
    strong_memoize(:indirectly_invite_members) do
      experiment_enabled?(:invite_members_version_b) && !can_import_members?
    end
  end

  def invite_group_members?(group)
    experiment_enabled?(:invite_members_empty_group_version_a) && Ability.allowed?(current_user, :admin_group_member, group)
  end
end
