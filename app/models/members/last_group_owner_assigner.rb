# frozen_string_literal: true

# Optimization class to fix group member n+1 queries
class LastGroupOwnerAssigner
  def initialize(group, members)
    @group = group
    @members = members
  end

  def execute
    @last_blocked_owner = no_owners_in_hierarchy? && group.single_blocked_owner?
    @group_single_owner = owners.size == 1

    members.each { |member| set_last_owner(member) }
  end

  private

  attr_reader :group, :members, :last_blocked_owner, :group_single_owner

  def no_owners_in_hierarchy?
    owners.empty?
  end

  def set_last_owner(member)
    member.last_owner = member.id.in?(owner_ids) && group_single_owner
    member.last_blocked_owner = member.id.in?(blocked_owner_ids) && last_blocked_owner
  end

  def owner_ids
    @owner_ids ||= owners.where(id: member_ids).ids
  end

  def blocked_owner_ids
    @blocked_owner_ids ||= group.blocked_owners.where(id: member_ids).ids
  end

  def member_ids
    @members_ids ||= members.pluck(:id)
  end

  def owners
    @owners ||= group.member_owners_excluding_project_bots.load
  end
end
