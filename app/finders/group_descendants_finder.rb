class GroupDescendantsFinder
  include Gitlab::Allowable

  attr_reader :current_user, :parent_group, :params

  def initialize(current_user: nil, parent_group:, params: {})
    @current_user = current_user
    @parent_group = parent_group
    @params = params
  end

  def execute
    Kaminari.paginate_array(children)
  end

  # This allows us to fetch only the count without loading the objects. Unless
  # the objects were already loaded.
  def total_count
    @total_count ||= subgroup_count + project_count
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
    @children ||= subgroups.with_route.includes(:parent) + projects.with_route.includes(:namespace)
  end

  def direct_child_groups
    GroupsFinder.new(current_user,
                     parent: parent_group,
                     all_available: true).execute
  end

  def all_descendant_groups
    Gitlab::GroupHierarchy.new(Group.where(id: parent_group)).base_and_descendants
  end

  def subgroups_matching_filter
    all_descendant_groups.where.not(id: parent_group).search(params[:filter])
  end

  def subgroups
    return Group.none unless Group.supports_nested_groups?
    return Group.none unless can?(current_user, :read_group, parent_group)

    # When filtering subgroups, we want to find all matches withing the tree of
    # descendants to show to the user
    groups = if params[:filter]
               subgroups_matching_filter
             else
               direct_child_groups
             end
    groups.sort(params[:sort])
  end

  def direct_child_projects
    GroupProjectsFinder.new(group: parent_group, params: params, current_user: current_user).execute
  end

  def projects_matching_filter
    ProjectsFinder.new(current_user: current_user).execute
      .search(params[:filter])
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
