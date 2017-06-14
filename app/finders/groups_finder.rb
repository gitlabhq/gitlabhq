class GroupsFinder < UnionFinder
  def initialize(current_user = nil, params = {})
    @current_user = current_user
    @params = params
  end

  def execute
    items = all_groups.map do |item|
      by_parent(item)
    end
    find_union(items, Group).with_route.order_id_desc
  end

  private

  attr_reader :current_user, :params

  def all_groups
    groups = []

    if current_user
      groups << Gitlab::GroupHierarchy.new(groups_for_ancestors, groups_for_descendants).all_groups
    end
    groups << Group.unscoped.public_to_user(current_user)

    groups
  end

  def groups_for_ancestors
    current_user.authorized_groups
  end

  def groups_for_descendants
    current_user.groups
  end

  def by_parent(groups)
    return groups unless params[:parent]

    groups.where(parent: params[:parent])
  end
end
