class GroupsFinder
  # Finds the groups available to the given user.
  #
  # current_user - The user to find the groups for.
  #
  # Returns an ActiveRecord::Relation.
  def execute(current_user = nil)
    if current_user
      relation = groups_visible_to_user(current_user)
    else
      relation = public_groups
    end

    relation.order_id_desc
  end

  private

  # This method returns the groups "current_user" can see.
  def groups_visible_to_user(current_user)
    base = groups_for_projects(public_and_internal_projects)

    union = Gitlab::SQL::Union.
      new([base.select(:id), current_user.authorized_groups.select(:id)])

    Group.where("namespaces.id IN (#{union.to_sql})")
  end

  def public_groups
    groups_for_projects(public_projects)
  end

  def groups_for_projects(projects)
    Group.public_and_given_groups(projects.select(:namespace_id))
  end

  def public_projects
    Project.unscoped.public_only
  end

  def public_and_internal_projects
    Project.unscoped.public_and_internal_only
  end
end
