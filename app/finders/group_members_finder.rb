# frozen_string_literal: true

class GroupMembersFinder < UnionFinder
  RELATIONS = %i(direct inherited descendants).freeze
  DEFAULT_RELATIONS = %i(direct inherited).freeze

  include CreatedAtFilter

  # Params can be any of the following:
  #   two_factor: string. 'enabled' or 'disabled' are returning different set of data, other values are not effective.
  #   sort:       string
  #   search:     string
  #   created_after: datetime
  #   created_before: datetime
  attr_reader :params

  def initialize(group, user = nil, params: {})
    @group = group
    @user = user
    @params = params
  end

  def execute(include_relations: DEFAULT_RELATIONS)
    group_members = group_members_list
    relations = []

    return filter_members(group_members) if include_relations == [:direct]

    relations << group_members if include_relations.include?(:direct)

    if include_relations.include?(:inherited) && group.parent
      parents_members = relation_group_members(group.ancestors)

      relations << parents_members
    end

    if include_relations.include?(:descendants)
      descendant_members = relation_group_members(group.descendants)

      relations << descendant_members
    end

    return GroupMember.none if relations.empty?

    members = find_union(relations, GroupMember)
    filter_members(members)
  end

  private

  attr_reader :user, :group

  def filter_members(members)
    members = members.search(params[:search]) if params[:search].present?
    members = members.sort_by_attribute(params[:sort]) if params[:sort].present?

    if params[:two_factor].present? && can_manage_members
      members = members.filter_by_2fa(params[:two_factor])
    end

    by_created_at(members)
  end

  def can_manage_members
    Ability.allowed?(user, :admin_group_member, group)
  end

  def group_members_list
    group.members
  end

  def relation_group_members(relation)
    all_group_members(relation).non_minimal_access
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def all_group_members(relation)
    GroupMember.non_request
      .where(source_id: relation.select(:id))
      .where.not(user_id: group.users.select(:id))
  end
  # rubocop: enable CodeReuse/ActiveRecord
end

GroupMembersFinder.prepend_if_ee('EE::GroupMembersFinder')
