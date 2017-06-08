class GroupsFinder < UnionFinder
  def initialize(current_user = nil, params = {})
    @current_user = current_user
    @params = params
  end

  def execute
    groups = find_union(all_groups, Group).with_route.order_id_desc
    by_parent(groups)
  end

  private

  attr_reader :current_user, :params

  def all_groups
    groups = []

    if current_user
      groups << Group.member_self_and_descendants(current_user.id)
      groups << current_user.groups_through_project_authorizations
    end
    groups << Group.unscoped.public_to_user(current_user)

    groups
  end

  def by_parent(groups)
    return groups unless params[:parent]

    groups.where(parent: params[:parent])
  end
end
