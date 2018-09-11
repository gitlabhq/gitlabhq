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
#
# Users with full private access can see all groups. The `owned` and `parent`
# params can be used to restrict the groups that are returned.
#
# Anonymous users will never return any `owned` groups. They will return all
# public groups instead, even if `all_available` is set to false.
class GroupsFinder < UnionFinder
  include CustomAttributesFilter

  def initialize(current_user = nil, params = {})
    @current_user = current_user
    @params = params
  end

  def execute
    items = all_groups.map do |item|
      item = by_parent(item)
      item = by_custom_attributes(item)

      item
    end

    find_union(items, Group).with_route.order_id_desc
  end

  private

  attr_reader :current_user, :params

  def all_groups
    return [owned_groups] if params[:owned]
    return [groups_with_min_access_level] if min_access_level?
    return [Group.all] if current_user&.full_private_access? && all_available?

    groups = []
    groups << Gitlab::GroupHierarchy.new(groups_for_ancestors, groups_for_descendants).all_groups if current_user
    groups << Group.unscoped.public_to_user(current_user) if include_public_groups?
    groups << Group.none if groups.empty?
    groups
  end

  def groups_for_ancestors
    current_user.authorized_groups
  end

  def groups_for_descendants
    current_user.groups
  end

  def groups_with_min_access_level
    groups = current_user
      .groups
      .where('members.access_level >= ?', params[:min_access_level])

    Gitlab::GroupHierarchy
      .new(groups)
      .base_and_descendants
  end

  def by_parent(groups)
    return groups unless params[:parent]

    groups.where(parent: params[:parent])
  end

  def owned_groups
    current_user&.owned_groups || Group.none
  end

  def include_public_groups?
    current_user.nil? || all_available?
  end

  def all_available?
    params.fetch(:all_available, true)
  end

  def min_access_level?
    current_user && params[:min_access_level].present?
  end
end
