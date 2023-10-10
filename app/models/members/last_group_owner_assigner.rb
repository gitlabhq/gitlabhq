# frozen_string_literal: true

# Optimization class to fix group member n+1 queries
class LastGroupOwnerAssigner
  def initialize(group, members)
    @group = group
    @members = members
  end

  def execute
    @group_single_owner = owners.size == 1

    members.each { |member| set_last_owner(member) }
  end

  private

  attr_reader :group, :members, :group_single_owner

  def set_last_owner(member)
    member.last_owner = group_single_owner && member.id.in?(owner_ids)
  end

  def owner_ids
    @owner_ids ||= member_ids & owners.map(&:id)
  end

  def member_ids
    @members_ids ||= members.pluck(:id)
  end

  def owners
    @owners ||= group.member_owners_excluding_project_bots
  end
end
