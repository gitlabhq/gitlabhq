# frozen_string_literal: true

class GroupMembersFinder < UnionFinder
  RELATIONS = %i[direct inherited descendants shared_from_groups].freeze
  DEFAULT_RELATIONS = %i[direct inherited].freeze
  INVALID_RELATION_TYPE_ERROR_MSG = "is not a valid relation type. Valid relation types are #{RELATIONS.join(', ')}."

  RELATIONS_DESCRIPTIONS = {
    direct: 'Members in the group itself',
    inherited: "Members in the group's ancestor groups",
    descendants: "Members in the group's subgroups",
    shared_from_groups: "Invited group's members"
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
    groups = groups_by_relations(include_relations)
    members = all_group_members(groups).distinct_on_user_with_max_access_level

    filter_members(members)
  end

  private

  attr_reader :user, :group

  def groups_by_relations(include_relations)
    check_relation_arguments!(include_relations)

    related_groups = []

    related_groups << Group.by_id(group.id) if include_relations&.include?(:direct)
    related_groups << group.ancestors if include_relations&.include?(:inherited)
    related_groups << group.descendants if include_relations&.include?(:descendants)
    related_groups << Group.shared_into_ancestors(group).public_or_visible_to_user(user) if include_relations&.include?(:shared_from_groups)

    find_union(related_groups, Group)
  end

  def filter_members(members)
    members = members.search(params[:search]) if params[:search].present?
    members = members.sort_by_attribute(params[:sort]) if params[:sort].present?

    if params[:two_factor].present? && can_manage_members
      members = members.filter_by_2fa(params[:two_factor])
    end

    if params[:access_levels].present?
      members = members.by_access_level(params[:access_levels])
    end

    members = apply_additional_filters(members)

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

  def check_relation_arguments!(include_relations)
    unless include_relations & RELATIONS == include_relations
      raise ArgumentError, "#{(include_relations - RELATIONS).first} #{INVALID_RELATION_TYPE_ERROR_MSG}"
    end
  end

  def apply_additional_filters(members)
    # overridden in EE to include additional filtering conditions.
    members
  end
end

GroupMembersFinder.prepend_mod_with('GroupMembersFinder')
