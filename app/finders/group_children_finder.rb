class GroupChildrenFinder
  include Gitlab::Allowable

  attr_reader :current_user, :parent_group, :params

  def initialize(current_user = nil, parent_group:, params: {})
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
    @total_count ||= if defined?(@children)
                       children.size
                     else
                       child_groups.count + projects.count
                     end
  end

  private

  def children
    @children ||= child_groups + projects
  end

  def child_groups
    return Group.none unless Group.supports_nested_groups?
    return Group.none unless can?(current_user, :read_group, parent_group)

    groups = GroupsFinder.new(current_user,
                              parent: parent_group,
                              all_available: true,
                              all_children_for_parent: params[:filter_groups].present?).execute

    groups = groups.search(params[:filter]) if params[:filter].present?
    groups = groups.includes(:route).includes(:children)
    groups.sort(params[:sort])
  end

  def projects
    return Project.none unless can?(current_user, :read_group, parent_group)

    projects = GroupProjectsFinder.new(group: parent_group, params: params, current_user: current_user).execute
    projects = projects.includes(:route)
    projects = projects.search(params[:filter]) if params[:filter].present?
    projects.sort(params[:sort])
  end
end
