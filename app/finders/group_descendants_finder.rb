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
    GroupsFinder.new(current_user, parent: parent_group, all_available: true).execute # rubocop: disable CodeReuse/Finder
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def all_visible_descendant_groups
    groups_table = Group.arel_table
    visible_to_user = groups_table[:visibility_level]
                      .in(Gitlab::VisibilityLevel.levels_for_user(current_user))

    if current_user
      authorized_groups = GroupsFinder.new(current_user, all_available: false) # rubocop: disable CodeReuse/Finder
        .execute.arel.as('authorized')
      authorized_to_user = groups_table.project(1).from(authorized_groups)
        .where(authorized_groups[:id].eq(groups_table[:id]))
        .exists
      visible_to_user = visible_to_user.or(authorized_to_user)
    end

    parent_group.descendants.where(visible_to_user)
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
  def ancestors_of_groups(base_for_ancestors)
    Group.id_in(base_for_ancestors).self_and_ancestors(upto: parent_group.id)
  end

  def ancestors_of_filtered_projects
    # rubocop:disable Database/AvoidUsingPluckWithoutLimit, CodeReuse/ActiveRecord -- Limit of 100 max per page is defined in kaminari config
    groups_to_load_ancestors_of = paginated_projects_without_direct_descendents.pluck(:namespace_id)
    # rubocop:enable Database/AvoidUsingPluckWithoutLimit, CodeReuse/ActiveRecord
    ancestors_of_groups(groups_to_load_ancestors_of)
      .with_selects_for_list(archived: params[:archived])
  end

  def ancestors_of_filtered_subgroups
    ancestors_of_groups(paginated_subgroups_without_direct_descendents)
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

  def direct_child_projects
    GroupProjectsFinder # rubocop:disable CodeReuse/Finder
      .new(group: parent_group, current_user: current_user, params: params, options: { exclude_shared: true })
      .execute
  end

  # Finds all projects nested under `parent_group` or any of its descendant
  # groups
  def projects_matching_filter
    projects_nested_in_group = Project.in_namespace(parent_group.self_and_descendants.as_ids)
    params_with_search = params.merge(search: params[:filter])

    ProjectsFinder.new( # rubocop:disable CodeReuse/Finder
      params: params_with_search,
      current_user: current_user,
      project_ids_relation: projects_nested_in_group
    ).execute
  end

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
end
