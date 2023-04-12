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
    shared_from_groups = if include_relations&.include?(:shared_from_groups)
                           Group.shared_into_ancestors(group).public_or_visible_to_user(user)
                         end

    members = all_group_members(groups, shared_from_groups).distinct_on_user_with_max_access_level

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

    related_groups
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

    members = filter_by_user_type(members)
    members = apply_additional_filters(members)

    by_created_at(members)
  end

  def can_manage_members
    Ability.allowed?(user, :admin_group_member, group)
  end

  def group_members_list
    group.members
  end

  def all_group_members(groups, shared_from_groups)
    members_of_groups(groups, shared_from_groups).non_minimal_access
  end

  def members_of_groups(groups, shared_from_groups)
    if Feature.disabled?(:members_with_shared_group_access, @group.root_ancestor)
      groups << shared_from_groups unless shared_from_groups.nil?
      return GroupMember.non_request.of_groups(find_union(groups, Group))
    end

    members = GroupMember.non_request.of_groups(find_union(groups, Group))
    return members if shared_from_groups.nil?

    shared_members = GroupMember.non_request.of_groups(shared_from_groups)
    select_attributes = GroupMember.attribute_names
    members_shared_with_group_access = members_shared_with_group_access(shared_members, select_attributes)

    # `members` and `members_shared_with_group_access` should have even select values
    find_union([members.select(select_attributes), members_shared_with_group_access], GroupMember)
  end

  def members_shared_with_group_access(shared_members, select_attributes)
    group_group_link_table = GroupGroupLink.arel_table
    group_member_table = GroupMember.arel_table

    member_columns = select_attributes.map do |column_name|
      if column_name == 'access_level'
        args = [group_group_link_table[:group_access], group_member_table[:access_level]]
        smallest_value_arel(args, 'access_level')
      else
        group_member_table[column_name]
      end
    end

    # rubocop:disable CodeReuse/ActiveRecord
    shared_members
      .joins("LEFT OUTER JOIN group_group_links ON members.source_id = group_group_links.shared_with_group_id")
      .select(member_columns)
    # rubocop:enable CodeReuse/ActiveRecord
  end

  def smallest_value_arel(args, column_alias)
    Arel::Nodes::As.new(Arel::Nodes::NamedFunction.new('LEAST', args), Arel::Nodes::SqlLiteral.new(column_alias))
  end

  def check_relation_arguments!(include_relations)
    unless include_relations & RELATIONS == include_relations
      raise ArgumentError, "#{(include_relations - RELATIONS).first} #{INVALID_RELATION_TYPE_ERROR_MSG}"
    end
  end

  def filter_by_user_type(members)
    return members unless params[:user_type] && can_manage_members

    members.filter_by_user_type(params[:user_type])
  end

  def apply_additional_filters(members)
    # overridden in EE to include additional filtering conditions.
    members
  end
end

GroupMembersFinder.prepend_mod_with('GroupMembersFinder')
