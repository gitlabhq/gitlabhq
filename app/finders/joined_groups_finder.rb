# Class for finding the groups a user is a member of.
class JoinedGroupsFinder
  def initialize(user = nil)
    @user = user
  end

  # Finds the groups of the source user, optionally limited to those visible to
  # the current user.
  #
  # current_user - If given the groups of "@user" will only include the groups
  #                "current_user" can also see.
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

  # Returns the groups the user in "current_user" can see.
  #
  # This list includes all public/internal projects as well as the projects of
  # "@user" that "current_user" also has access to.
  def groups_visible_to_user(current_user)
    base  = @user.authorized_groups.visible_to_user(current_user)
    extra = public_and_internal_groups
    union = Gitlab::SQL::Union.new([base.select(:id), extra.select(:id)])

    Group.where("namespaces.id IN (#{union.to_sql})")
  end

  def public_groups
    groups_for_projects(@user.authorized_projects.public_only)
  end

  def public_and_internal_groups
    groups_for_projects(@user.authorized_projects.public_and_internal_only)
  end

  def groups_for_projects(projects)
    @user.groups.public_and_given_groups(projects.select(:namespace_id))
  end
end
