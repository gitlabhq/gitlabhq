class GroupDescendantsFinder
  include Gitlab::Allowable

  attr_reader :current_user, :parent_group, :params

  def initialize(current_user: nil, parent_group:, params: {})
    @current_user = current_user
    @parent_group = parent_group
    @params = params.reverse_merge(non_archived: true)
  end

  def execute
    # The children array might be extended with the ancestors of projects when
    # filtering. In that case, take the maximum so the aray does not get limited
    # Otherwise, allow paginating through all results
    #
    all_required_elements = children
    all_required_elements |= ancestors_for_projects if params[:filter]
    total_count = [all_required_elements.size, paginator.total_count].max

    Kaminari.paginate_array(all_required_elements, total_count: total_count)
  end

  def subgroup_count
    @subgroup_count ||= subgroups.count
  end

  def project_count
    @project_count ||= projects.count
  end

  private

  def children
    @children ||= paginator.paginate(params[:page])
  end

  def collections
    [subgroups.with_selects_for_list, projects]
  end

  def paginator
    Gitlab::MultiCollectionPaginator.new(*collections, per_page: params[:per_page])
  end

  def direct_child_groups
    GroupsFinder.new(current_user,
                     parent: parent_group,
                     all_available: true).execute
  end

  def all_visible_descendant_groups
    groups_table = Group.arel_table
    visible_for_user = groups_table[:visibility_level]
                         .in(Gitlab::VisibilityLevel.levels_for_user(current_user))
    visible_for_user = if current_user
                         visible_projects = GroupsFinder.new(current_user).execute.as('visible')
                         authorized = groups_table.project(1).from(visible_projects)
                                        .where(visible_projects[:id].eq(groups_table[:id]))
                                        .exists
                         visible_for_user.or(authorized)
                       end
    hierarchy_for_parent
      .descendants
      .where(visible_for_user)
  end

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
  def ancestors_for_groups(base_for_ancestors)
    Gitlab::GroupHierarchy.new(base_for_ancestors)
      .base_and_ancestors(upto: parent_group.id)
  end

  def ancestors_for_projects
    projects_to_load_ancestors_of = projects.where.not(namespace: parent_group)
    groups_to_load_ancestors_of = Group.where(id: projects_to_load_ancestors_of.select(:namespace_id))
    ancestors_for_groups(groups_to_load_ancestors_of)
      .with_selects_for_list
  end

  def subgroups
    return Group.none unless Group.supports_nested_groups?
    return Group.none unless can?(current_user, :read_group, parent_group)

    # When filtering subgroups, we want to find all matches withing the tree of
    # descendants to show to the user
    groups = if params[:filter]
               ancestors_for_groups(subgroups_matching_filter)
             else
               direct_child_groups
             end
    groups.order_by(sort)
  end

  def projects_for_user
    Project.public_or_visible_to_user(current_user).non_archived
  end

  def direct_child_projects
    projects_for_user.where(namespace: parent_group)
  end

  # Finds all projects nested under `parent_group` or any of it's descendant
  # groups
  def projects_matching_filter
    projects_for_user.search(params[:filter])
      .where(namespace_id: hierarchy_for_parent.base_and_descendants.select(:id))
  end

  def projects
    return Project.none unless can?(current_user, :read_group, parent_group)

    projects = if params[:filter]
                 projects_matching_filter
               else
                 direct_child_projects
               end
    projects.with_route.order_by(sort)
  end

  def sort
    params.fetch(:sort, 'id_asc')
  end

  def hierarchy_for_parent
    @hierarchy ||= Gitlab::GroupHierarchy.new(Group.where(id: parent_group.id))
  end
end
