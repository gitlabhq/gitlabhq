# frozen_string_literal: true

class GroupMembersFinder < UnionFinder
  # Params can be any of the following:
  #   two_factor: string. 'enabled' or 'disabled' are returning different set of data, other values are not effective.
  #   sort:       string
  #   search:     string

  def initialize(group, user = nil)
    @group = group
    @user = user
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def execute(include_relations: [:inherited, :direct], params: {})
    group_members = group.members
    relations = []

    return group_members if include_relations == [:direct]

    relations << group_members if include_relations.include?(:direct)

    if include_relations.include?(:inherited) && group.parent
      parents_members = GroupMember.non_request
        .where(source_id: group.ancestors.select(:id))
        .where.not(user_id: group.users.select(:id))

      relations << parents_members
    end

    if include_relations.include?(:descendants)
      descendant_members = GroupMember.non_request
        .where(source_id: group.descendants.select(:id))
        .where.not(user_id: group.users.select(:id))

      relations << descendant_members
    end

    members = find_union(relations, GroupMember)
    filter_members(members, params)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  private

  attr_reader :user, :group

  def filter_members(members, params)
    members = members.search(params[:search]) if params[:search].present?
    members = members.sort_by_attribute(params[:sort]) if params[:sort].present?

    if can_manage_members && params[:two_factor].present?
      members = members.filter_by_2fa(params[:two_factor])
    end

    members
  end

  def can_manage_members
    Ability.allowed?(user, :admin_group_member, group)
  end
end

GroupMembersFinder.prepend_if_ee('EE::GroupMembersFinder')
