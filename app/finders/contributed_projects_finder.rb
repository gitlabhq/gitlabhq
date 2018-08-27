class ContributedProjectsFinder < UnionFinder
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
  # rubocop: disable CodeReuse/ActiveRecord
  def execute(current_user = nil)
    segments = all_projects(current_user)

    find_union(segments, Project).includes(:namespace).order_id_desc
  end
  # rubocop: enable CodeReuse/ActiveRecord

  private

  def all_projects(current_user)
    projects = []

    projects << @user.contributed_projects.visible_to_user(current_user) if current_user
    projects << @user.contributed_projects.public_to_user(current_user)

    projects
  end
end
