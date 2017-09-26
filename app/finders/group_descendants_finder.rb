class GroupDescendantsFinder
  include Gitlab::Allowable

  attr_reader :current_user, :parent_group, :params

  def initialize(current_user: nil, parent_group:, params: {})
    @current_user = current_user
    @parent_group = parent_group
    @params = params.reverse_merge(non_archived: true)
  end

  def execute
    Kaminari.paginate_array(children)
  end

  def subgroup_count
    @subgroup_count ||= if defined?(@children)
                          children.count { |child| child.is_a?(Group) }
                        else
                          subgroups.count
                        end
  end

  def project_count
    @project_count ||= if defined?(@children)
                         children.count { |child| child.is_a?(Project) }
                       else
                         projects.count
                       end
  end

  private

  def children
    return @children if @children

    projects_count = <<~PROJECTCOUNT
                   (SELECT COUNT(projects.id) AS preloaded_project_count
                    FROM projects WHERE projects.namespace_id = namespaces.id)
                   PROJECTCOUNT
    subgroup_count = <<~SUBGROUPCOUNT
                     (SELECT COUNT(children.id) AS preloaded_subgroup_count
                      FROM namespaces children
                      WHERE children.parent_id = namespaces.id)
                     SUBGROUPCOUNT
    member_count = <<~MEMBERCOUNT
                   (SELECT COUNT(members.user_id) AS preloaded_member_count
                    FROM members
                    WHERE members.source_type = 'Namespace'
                    AND members.source_id = namespaces.id
                    AND members.requested_at IS NULL)
                   MEMBERCOUNT
    group_selects = [
      'namespaces.*',
      projects_count,
      subgroup_count,
      member_count
    ]

    subgroups_with_counts = subgroups.with_route.select(group_selects)

    if params[:filter]
      ancestors_for_project_search = ancestors_for_groups(Group.where(id: projects_matching_filter.select(:namespace_id)))
      subgroups_with_counts = ancestors_for_project_search.with_route.select(group_selects) | subgroups_with_counts
    end

    @children = subgroups_with_counts + projects.with_route
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

  def ancestors_for_groups(base_for_ancestors)
    Gitlab::GroupHierarchy.new(base_for_ancestors)
      .base_and_ancestors.where.not(id: parent_group)
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
    groups.sort(params[:sort])
  end

  def projects_for_user
    Project.public_or_visible_to_user(current_user).non_archived
  end

  def direct_child_projects
    projects_for_user.where(namespace: parent_group)
  end

  def projects_matching_filter
    projects_for_user.search(params[:filter])
      .where(namespace: all_descendant_groups)
  end

  def projects
    return Project.none unless can?(current_user, :read_group, parent_group)

    projects = if params[:filter]
                 projects_matching_filter
               else
                 direct_child_projects
               end
    projects.sort(params[:sort])
  end
end
