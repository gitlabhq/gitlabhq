class GroupDescendantsFinder
  include Gitlab::Allowable

  attr_reader :current_user, :parent_group, :params

  PROJECT_COUNT_SQL = <<~PROJECTCOUNT.freeze
                     (SELECT COUNT(*) AS preloaded_project_count
                      FROM projects
                      WHERE projects.namespace_id = namespaces.id
                      AND projects.archived IS NOT true)
                     PROJECTCOUNT
  SUBGROUP_COUNT_SQL = <<~SUBGROUPCOUNT.freeze
                     (SELECT COUNT(*) AS preloaded_subgroup_count
                      FROM namespaces children
                      WHERE children.parent_id = namespaces.id)
                     SUBGROUPCOUNT
  MEMBER_COUNT_SQL = <<~MEMBERCOUNT.freeze
                     (SELECT COUNT(*) AS preloaded_member_count
                     FROM members
                     WHERE members.source_type = 'Namespace'
                     AND members.source_id = namespaces.id
                     AND members.requested_at IS NULL)
                     MEMBERCOUNT

  GROUP_SELECTS = ['namespaces.*',
                   PROJECT_COUNT_SQL,
                   SUBGROUP_COUNT_SQL,
                   MEMBER_COUNT_SQL].freeze

  def initialize(current_user: nil, parent_group:, params: {})
    @current_user = current_user
    @parent_group = parent_group
    @params = params.reverse_merge(non_archived: true)
  end

  def execute
    # The children array might be extended with the ancestors of projects when
    # filtering. In that case, take the maximum so the aray does not get limited
    # Otherwise, allow paginating through the search results
    #
    total_count = [children.size, subgroup_count + project_count].max
    Kaminari.paginate_array(children, total_count: total_count)
  end

  def subgroup_count
    @subgroup_count ||= subgroups.count
  end

  def project_count
    @project_count ||= projects.count
  end

  private

  def children
    return @children if @children

    subgroups_with_counts = subgroups.with_route
                              .page(params[:page]).per(per_page)
                              .select(GROUP_SELECTS)

    paginated_projects = projects.with_route.page(subgroup_page - group_page_count)
                           .per(per_page - subgroups_with_counts.size)

    if params[:filter]
      ancestors_for_project_search = ancestors_for_groups(Group.where(id: paginated_projects.select(:namespace_id)))
      subgroups_with_counts = ancestors_for_project_search.with_route.select(GROUP_SELECTS) | subgroups_with_counts
    end

    @children = subgroups_with_counts + paginated_projects
  end

  def direct_child_groups
    GroupsFinder.new(current_user,
                     parent: parent_group,
                     all_available: true).execute
  end

  def all_visible_descendant_groups
    groups_table = Group.arel_table
    visible_for_user = if current_user
                         groups_table[:id].in(
                           Arel::Nodes::SqlLiteral.new(GroupsFinder.new(current_user, all_available: true).execute.select(:id).to_sql)
                         )
                       else
                         groups_table[:visibility_level].eq(Gitlab::VisibilityLevel::PUBLIC)
                       end

    Gitlab::GroupHierarchy.new(Group.where(id: parent_group))
      .base_and_descendants
      .where(visible_for_user)
  end

  def subgroups_matching_filter
    all_visible_descendant_groups
      .where.not(id: parent_group)
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
    ancestors_for_parent = Gitlab::GroupHierarchy.new(Group.where(id: parent_group))
                             .base_and_ancestors
    Gitlab::GroupHierarchy.new(base_for_ancestors)
      .base_and_ancestors.where.not(id: ancestors_for_parent)
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

  def projects_matching_filter
    projects_for_user.search(params[:filter])
      .where(namespace: all_visible_descendant_groups)
  end

  def projects
    return Project.none unless can?(current_user, :read_group, parent_group)

    projects = if params[:filter]
                 projects_matching_filter
               else
                 direct_child_projects
               end
    projects.order_by(sort)
  end

  def sort
    params.fetch(:sort, 'id_asc')
  end

  def per_page
    params.fetch(:per_page, Kaminari.config.default_per_page)
  end
end
