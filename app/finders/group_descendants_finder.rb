# frozen_string_literal: true

# GroupDescendantsFinder
#
# Used to find and filter all subgroups and projects of a passed parent group
# visible to a specified user.
#
# When passing a `filter` param, the search is performed over all nested levels
# of the `parent_group`. All ancestors for a search result are loaded
#
# Arguments:
#   current_user: The user for which the children should be visible
#   parent_group: The group to find children of
#   params:
#     Supports all params that the `ProjectsFinder` and `GroupProjectsFinder`
#     support.
#
#     filter: string - is aliased to `search` for consistency with the frontend
#     archived: string - `only` or `true`.
#                        `non_archived` is passed to the `ProjectFinder`s if none
#                        was given.
class GroupDescendantsFinder
  include Gitlab::Utils::StrongMemoize

  attr_reader :current_user, :parent_group, :params

  def initialize(parent_group:, current_user: nil, params: {})
    @current_user = current_user
    @parent_group = parent_group
    @params = params.reverse_merge(non_archived: params[:archived].blank?, not_aimed_for_deletion: true)
  end

  def execute
    # The children array might be extended with the ancestors of projects and
    # subgroups when filtering. In that case, take the maximum so the array does
    # not get limited otherwise, allow paginating through all results.
    #
    all_required_elements = children
    if params[:filter]
      all_required_elements |= ancestors_of_filtered_subgroups
      all_required_elements |= ancestors_of_filtered_projects
    end

    total_count = [all_required_elements.size, paginator.total_count].max

    Kaminari.paginate_array(all_required_elements, total_count: total_count)
  end

  private

  def children
    @children ||= paginator.paginate(page)
  end

  def paginator
    @paginator ||= Gitlab::MultiCollectionPaginator.new(
      subgroups,
      projects.with_route,
      per_page: params[:per_page]
    )
  end

  def direct_child_groups
    # rubocop: disable CodeReuse/Finder
    GroupsFinder.new(current_user, parent: parent_group, all_available: true).execute
    # rubocop: enable CodeReuse/Finder
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def all_visible_descendant_groups
    # rubocop: disable CodeReuse/Finder
    groups_table = Group.arel_table
    visible_to_user = groups_table[:visibility_level]
                      .in(Gitlab::VisibilityLevel.levels_for_user(current_user))

    if current_user
      authorized_groups = GroupsFinder.new(current_user, all_available: false)
        .execute.arel.as('authorized')
      authorized_to_user = groups_table.project(1).from(authorized_groups)
        .where(authorized_groups[:id].eq(groups_table[:id]))
        .exists
      visible_to_user = visible_to_user.or(authorized_to_user)
    end

    parent_group.descendants.where(visible_to_user)
    # rubocop: enable CodeReuse/Finder
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def subgroups_matching_filter
    all_visible_descendant_groups
      .search(params[:filter])
  end

  # When filtering we want all to preload all the ancestors upto the specified
  # parent group.
  #
  # - root
  #   - subgroup
  #     - nested-group
  #       - project
  #
  # So when searching 'project', on the 'subgroup' page we want to preload
  # 'nested-group' but not 'subgroup' or 'root'
  # rubocop: disable CodeReuse/ActiveRecord
  def ancestors_of_groups(base_for_ancestors)
    group_ids = if select_ancestors_of_paginated_items_feature_enabled?
                  base_for_ancestors
                else
                  base_for_ancestors.except(:select, :sort).select(:id)
                end

    Group.where(id: group_ids).self_and_ancestors(upto: parent_group.id)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  # rubocop: disable CodeReuse/ActiveRecord
  def ancestors_of_filtered_projects
    # rubocop:disable Database/AvoidUsingPluckWithoutLimit -- Limit of 100 max per page is defined in kaminari config
    groups_to_load_ancestors_of = if select_ancestors_of_paginated_items_feature_enabled?
                                    paginated_projects_without_direct_descendents.pluck(:namespace_id)
                                  else
                                    projects_to_load_ancestors_of = projects.where.not(namespace: parent_group)
                                    Group.where(id: projects_to_load_ancestors_of.select(:namespace_id))
                                  end
    # rubocop:enable Database/AvoidUsingPluckWithoutLimit
    ancestors_of_groups(groups_to_load_ancestors_of)
      .with_selects_for_list(archived: params[:archived])
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def ancestors_of_filtered_subgroups
    subgroups_to_find_ancestors = if select_ancestors_of_paginated_items_feature_enabled?
                                    paginated_subgroups_without_direct_descendents
                                  else
                                    subgroups
                                  end

    ancestors_of_groups(subgroups_to_find_ancestors)
      .with_selects_for_list(archived: params[:archived])
  end

  def subgroups
    # When filtering subgroups, we want to find all matches within the tree of
    # descendants to show to the user
    groups = if params[:filter]
               subgroups_matching_filter
             else
               direct_child_groups
             end

    groups.with_selects_for_list(archived: params[:archived]).order_by(sort)
  end

  # rubocop: disable CodeReuse/Finder
  def direct_child_projects
    GroupProjectsFinder
      .new(group: parent_group, current_user: current_user, params: params, options: { exclude_shared: true })
      .execute
  end
  # rubocop: enable CodeReuse/Finder

  # Finds all projects nested under `parent_group` or any of its descendant
  # groups
  # rubocop: disable CodeReuse/ActiveRecord
  def projects_matching_filter
    # rubocop: disable CodeReuse/Finder
    projects_nested_in_group = Project.where(namespace_id: parent_group.self_and_descendants.as_ids)
    params_with_search = params.merge(search: params[:filter])

    ProjectsFinder.new(
      params: params_with_search,
      current_user: current_user,
      project_ids_relation: projects_nested_in_group
    ).execute
    # rubocop: enable CodeReuse/Finder
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def projects
    projects = if params[:filter]
                 projects_matching_filter
               else
                 direct_child_projects
               end

    projects.with_route.order_by(sort)
  end

  def sort
    params.fetch(:sort, 'name_asc')
  end

  def paginated_subgroups_without_direct_descendents
    # We remove direct descendants (ie. item.parent_id == parent_group.id) as we already have their parent
    # i.e. `parent_group`.
    paginator
      .paginated_first_collection(page)
      .reject { |item| item.parent_id == parent_group.id }
  end

  def paginated_projects_without_direct_descendents
    # We remove direct descendants (ie. item.namespace_id == parent_group.id) as we already have their parent
    # i.e. `parent_group`.
    paginator
      .paginated_second_collection(page)
      .reject { |item| item.namespace_id == parent_group.id }
  end

  def page
    params[:page].to_i
  end

  def select_ancestors_of_paginated_items_feature_enabled?
    Feature.enabled?(:select_ancestors_of_paginated_items, parent_group.root_ancestor, type: :gitlab_com_derisk)
  end
  strong_memoize_attr :select_ancestors_of_paginated_items_feature_enabled?
end
