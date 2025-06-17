# frozen_string_literal: true

# GroupDescendantsFinder
#
# Used to find and filter all subgroups and projects of a passed parent group
# visible to a specified user.
#
# Arguments:
#   current_user: The user for which the children should be visible
#   parent_group: The group to find children of
#   params:
#     Supports all params that the `ProjectsFinder` and `GroupProjectsFinder`
#     support.
#
#     active: boolean - filters for active descendants. When `false`, the search is performed over
#                       all nested levels of the `parent group` and all inactive ancestors are loaded.
#     filter: string - aliased to `search` for consistency with the frontend. When a filter is
#                      passed, the search is performed over all nested levels of the `parent_group`.
#                      All ancestors for a search result are loaded
class GroupDescendantsFinder
  include Gitlab::Utils::StrongMemoize

  attr_reader :current_user, :parent_group, :params

  def initialize(parent_group:, current_user: nil, params: {})
    @current_user = current_user
    @parent_group = parent_group
    @params = params
  end

  def execute
    # First paginate and then include the ancestors of the filtered children to:
    # - Avoid truncating children or preloaded ancestors due to per_page limit
    # - Ensure correct pagination headers are returned
    all_required_elements = Kaminari.paginate_array(children, total_count: paginator.total_count)
                                    .page(page)

    preloaded_ancestors = []
    if search_descendants?
      preloaded_ancestors |= ancestors_of_filtered_subgroups
      preloaded_ancestors |= ancestors_of_filtered_projects
    end

    all_required_elements.concat(preloaded_ancestors - children)
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
    GroupsFinder # rubocop: disable CodeReuse/Finder
      .new(current_user, parent: parent_group, all_available: true, active: params[:active])
      .execute
  end

  def descendant_groups
    descendants = parent_group.descendants
    descendants = by_visible_to_users(descendants)
    descendants = by_active(descendants)
    by_search(descendants)
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
    ancestors = Group.id_in(base_for_ancestors).self_and_ancestors(upto: parent_group.id)
    ancestors = ancestors.self_or_ancestors_inactive if inactive?
    ancestors
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
    groups = if search_descendants?
               descendant_groups
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
  def descendant_projects
    projects_nested_in_group = Project.in_namespace(parent_group.self_and_descendants.as_ids)

    finder_params = params.dup
    finder_params[:search] = params[:filter] if params[:filter]

    ProjectsFinder.new( # rubocop:disable CodeReuse/Finder
      params: finder_params,
      current_user: current_user,
      project_ids_relation: projects_nested_in_group
    ).execute
  end

  def projects
    projects = if search_descendants?
                 descendant_projects
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

  # Filters group descendants to only include those visible to the current user.
  #
  # This method applies visibility filtering based on two criteria:
  # 1. Groups with visibility level accessible to the current user
  # 2. Groups where the user has explicit authorization (if authenticated)
  #
  # @param descendants [ActiveRecord::Relation<Group>] The collection of group descendants to filter
  # @return [ActiveRecord::Relation<Group>] Filtered descendants visible to the current user
  # rubocop: disable CodeReuse/ActiveRecord -- Needs specialized queries for optimization
  def by_visible_to_users(descendants)
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

    descendants.where(visible_to_user)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def by_active(descendants)
    return descendants if params[:active].nil?

    params[:active] ? descendants.self_and_ancestors_active : descendants.self_or_ancestors_inactive
  end

  def by_search(descendants)
    return descendants unless params[:filter]

    descendants.search(params[:filter])
  end

  def inactive?
    params[:active] == false
  end

  def search_descendants?
    params[:filter].present? || inactive?
  end
end
