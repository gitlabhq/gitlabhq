# frozen_string_literal: true

# GroupsFinder
#
# Used to filter Groups by a set of params
#
# Arguments:
#   current_user - which user is requesting groups
#   params:
#     owned: boolean
#     parent: Group
#     all_available: boolean (defaults to true)
#     min_access_level: integer
#     search: string
#     exclude_group_ids: array of integers
#     filter_group_ids: array of integers - only include groups from the specified list of ids
#     include_parent_descendants: boolean (defaults to false) - includes descendant groups when
#                                 filtering by parent. The parent param must be present.
#     include_parent_shared_groups: boolean (defaults to false) - includes shared groups of a parent group
#                                 when filtering by parent.
#                                 Both parent and include_parent_descendants params must be present.
#     include_ancestors: boolean (defaults to true)
#     organization: Scope the groups to the Organizations::Organization
#
# Users with full private access can see all groups. The `owned` and `parent`
# params can be used to restrict the groups that are returned.
#
# Anonymous users will never return any `owned` groups. They will return all
# public groups instead, even if `all_available` is set to false.
class GroupsFinder < UnionFinder
  include CustomAttributesFilter
  include Namespaces::GroupsFilter

  attr_reader :current_user, :params

  def initialize(current_user = nil, params = {})
    @current_user = current_user
    @params = params
  end

  def execute
    # filtered_groups can contain an array of scopes, so these
    # are combined into a single query using UNION.
    groups = find_union(filtered_groups, Group)
    sort(groups).with_route
  end

  private

  def filtered_groups
    all_groups.map do |groups|
      filter_groups(groups)
    end
  end

  def all_groups
    return [owned_groups] if params[:owned]
    return [groups_with_min_access_level] if min_access_level?
    return [Group.all] if current_user&.can_read_all_resources? && all_available?

    groups = [
      authorized_groups,
      public_groups
    ].compact

    groups << Group.none if groups.empty?

    groups
  end

  def owned_groups
    current_user&.owned_groups || Group.none
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def groups_with_min_access_level
    inner_query = current_user
      .groups
      .where('members.access_level >= ?', params[:min_access_level])
      .self_and_descendants
    cte = Gitlab::SQL::CTE.new(:groups_with_min_access_level_cte, inner_query)
    cte.apply_to(Group.where({}))
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def authorized_groups
    return unless current_user

    if params.fetch(:include_ancestors, true)
      current_user.authorized_groups.self_and_ancestors
    else
      current_user.authorized_groups
    end
  end

  def public_groups
    # By default, all groups public to the user are included. This is controlled by
    # the :all_available argument, which defaults to true
    return unless include_public_groups?

    Group.unscoped.public_to_user(current_user)
  end

  def filter_groups(groups)
    groups = by_organization(groups)
    groups = by_parent(groups)
    groups = by_custom_attributes(groups)
    groups = filter_group_ids(groups)
    groups = exclude_group_ids(groups)
    groups = by_visibility(groups)
    groups = by_ids(groups)
    groups = top_level_only(groups)
    by_search(groups)
  end

  def by_organization(groups)
    organization = params[:organization]
    return groups unless organization

    groups.in_organization(organization)
  end

  def by_parent(groups)
    return groups unless params[:parent]

    if include_parent_descendants?
      by_parent_descendants(groups, params[:parent])
    else
      by_parent_children(groups, params[:parent])
    end
  end

  def by_parent_descendants(groups, parent)
    if include_parent_shared_groups?
      groups.descendants_with_shared_with_groups(parent)
    else
      groups.id_in(parent.descendants)
    end
  end

  def by_parent_children(groups, parent)
    groups.by_parent(parent)
  end

  def filter_group_ids(groups)
    return groups unless params[:filter_group_ids]

    groups.id_in(params[:filter_group_ids])
  end

  def exclude_group_ids(groups)
    return groups unless params[:exclude_group_ids]

    groups.id_not_in(params[:exclude_group_ids])
  end

  def include_parent_shared_groups?
    params.fetch(:include_parent_shared_groups, false)
  end

  def include_parent_descendants?
    params.fetch(:include_parent_descendants, false)
  end

  def include_public_groups?
    current_user.nil? || all_available?
  end

  def all_available?
    params.fetch(:all_available, true)
  end
end

GroupsFinder.prepend_mod_with('GroupsFinder')
