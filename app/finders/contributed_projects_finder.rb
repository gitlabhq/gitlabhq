class ContributedProjectsFinder
  def initialize(user)
    @user = user
  end

  # Finds the projects "@user" contributed to, limited to either public projects
  # or projects visible to the given user.
  #
  # current_user - When given the list of the projects is limited to those only
  #                visible by this user.
  #
  # Returns an ActiveRecord::Relation.
  def execute(current_user = nil)
    if current_user
      relation = projects_visible_to_user(current_user)
    else
      relation = public_projects
    end

    relation.includes(:namespace).order_id_desc
  end

  private

  def projects_visible_to_user(current_user)
    authorized = @user.contributed_projects.visible_to_user(current_user)

    union = Gitlab::SQL::Union.
      new([authorized.select(:id), public_projects.select(:id)])

    Project.where("projects.id IN (#{union.to_sql})")
  end

  def public_projects
    @user.contributed_projects.public_only
  end
end
