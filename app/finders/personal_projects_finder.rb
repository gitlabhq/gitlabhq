class PersonalProjectsFinder < UnionFinder
  def initialize(user)
    @user = user
  end

  # Finds the projects belonging to the user in "@user", limited to either
  # public projects or projects visible to the given user.
  #
  # current_user - When given the list of projects is limited to those only
  #                visible by this user.
  #
  # Returns an ActiveRecord::Relation.
  def execute(current_user = nil)
    segments = all_projects(current_user)

    find_union(segments, Project).includes(:namespace).order_id_desc
  end

  private

  def all_projects(current_user)
    projects = []

    projects << @user.personal_projects.visible_to_user(current_user) if current_user
    projects << @user.personal_projects.public_to_user(current_user)

    projects
  end
end
