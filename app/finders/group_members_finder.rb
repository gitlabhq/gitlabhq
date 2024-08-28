# frozen_string_literal: true

class GroupMembersFinder < UnionFinder
  RELATIONS = %i[direct inherited descendants shared_from_groups].freeze
  DEFAULT_RELATIONS = %i[direct inherited].freeze
  INVALID_RELATION_TYPE_ERROR_MSG =
    "is not a valid relation type. Valid relation types are #{RELATIONS.join(', ')}.".freeze

  RELATIONS_DESCRIPTIONS = {
    direct: 'Members in the group itself',
    inherited: "Members in the group's ancestor groups",
    descendants: "Members in the group's subgroups",
    shared_from_groups: "Invited group's members"
  }.freeze

  include CreatedAtFilter
  include Members::RoleParser

  # Params can be any of the following:
  #   two_factor: string. 'enabled' or 'disabled' are returning different set of data, other values are not effective.
  #   sort:       string
  #   search:     string
  #   created_after: datetime
  #   created_before: datetime
  #   non_invite:      boolean
  #   with_custom_role: boolean
  attr_reader :params

  def initialize(group, user = nil, params: {})
    @group = group
    @user = user
    @params = params
  end

  def execute(include_relations: DEFAULT_RELATIONS)
    groups = groups_by_relations(include_relations)

    members = all_group_members(groups)
    members = members.distinct_on_user_with_max_access_level(group) if static_roles_only?

    filter_members(members)
  end

  private

  attr_reader :user, :group

  def groups_by_relations(include_relations)
    check_relation_arguments!(include_relations)

    related_groups = {}

    related_groups[:direct] = Group.by_id(group.id) if include_relations.include?(:direct)
    related_groups[:inherited] = group.ancestors if include_relations.include?(:inherited)
    related_groups[:descendants] = group.descendants if include_relations.include?(:descendants)

    if include_relations.include?(:shared_from_groups)
      related_groups[:shared_from_groups] =
        if group.member?(user)
          Group.shared_into_ancestors(group)
        else
          Group.shared_into_ancestors(group).public_or_visible_to_user(user)
        end
    end

    related_groups
  end

  def filter_members(members)
    members = members.search(params[:search]) if params[:search].present?
    members = members.sort_by_attribute(params[:sort]) if params[:sort].present?

    members = members.filter_by_2fa(params[:two_factor]) if params[:two_factor].present? && can_manage_members
    members = members.by_access_level(params[:access_levels]) if params[:access_levels].present?

    members = filter_by_user_type(members)
    members = filter_by_max_role(members)
    members = apply_additional_filters(members)

    members = by_created_at(members)
    members = members.non_invite if params[:non_invite]

    members
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
    groups_except_from_sharing = groups.except(:shared_from_groups).values
    groups_as_union = find_union(groups_except_from_sharing, Group)
    members = GroupMember.non_request.of_groups(groups_as_union)

    shared_from_groups = groups[:shared_from_groups]
    return members if shared_from_groups.nil?

    # We limit the `access_level` of the shared members to the access levels of the `group_group_links` created
    # with the group or its ancestors because the shared members cannot have access greater than the `group_group_links`
    # with itself or its ancestors.
    shared_members = GroupMember.non_request.of_groups(shared_from_groups)
                                .with_group_group_sharing_access(
                                  group.self_and_ancestors,
                                  custom_role_for_group_link_enabled?(group)
                                )
    # `members` and `shared_members` should have even select values
    find_union([members.select(Member.column_names), shared_members], GroupMember)
  end

  def check_relation_arguments!(include_relations)
    return if (include_relations - RELATIONS).empty?

    raise ArgumentError, "#{(include_relations - RELATIONS).first} #{INVALID_RELATION_TYPE_ERROR_MSG}"
  end

  def filter_by_user_type(members)
    return members unless params[:user_type] && can_manage_members

    members.filter_by_user_type(params[:user_type])
  end

  def filter_by_max_role(members)
    max_role = get_access_level(params[:max_role])
    return members unless max_role&.in?(group.access_level_roles.values)

    members.all_by_access_level(max_role).with_static_role
  end

  def apply_additional_filters(members)
    # overridden in EE to include additional filtering conditions.
    members
  end

  def static_roles_only?
    true
  end

  # overridden in EE
  def custom_role_for_group_link_enabled?(_group)
    false
  end
end

GroupMembersFinder.prepend_mod_with('GroupMembersFinder')
