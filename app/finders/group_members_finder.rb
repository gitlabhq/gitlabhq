# frozen_string_literal: true

class GroupMembersFinder < UnionFinder
  RELATIONS = %i(direct inherited descendants).freeze
  DEFAULT_RELATIONS = %i(direct inherited).freeze

  RELATIONS_DESCRIPTIONS = {
    direct: 'Members in the group itself',
    inherited: "Members in the group's ancestor groups",
    descendants: "Members in the group's subgroups"
  }.freeze

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
    return filter_members(group_members_list) if include_relations == [:direct]

    groups = groups_by_relations(include_relations)
    return GroupMember.none unless groups

    members = all_group_members(groups).distinct_on_user_with_max_access_level

    filter_members(members)
  end

  private

  attr_reader :user, :group

  def groups_by_relations(include_relations)
    case include_relations.sort
    when [:inherited]
      group.ancestors
    when [:descendants]
      group.descendants
    when [:direct, :inherited]
      group.self_and_ancestors
    when [:descendants, :direct]
      group.self_and_descendants
    when [:descendants, :inherited]
      find_union([group.ancestors, group.descendants], Group)
    when [:descendants, :direct, :inherited]
      group.self_and_hierarchy
    else
      nil
    end
  end

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

  def all_group_members(groups)
    members_of_groups(groups).non_minimal_access
  end

  def members_of_groups(groups)
    GroupMember.non_request.of_groups(groups)
  end
end

GroupMembersFinder.prepend_mod_with('GroupMembersFinder')
