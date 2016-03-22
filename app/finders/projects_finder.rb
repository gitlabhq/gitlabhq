class ProjectsFinder < UnionFinder
  def execute(current_user = nil, options = {})
    segments = all_projects(current_user)

    find_union(segments, Project)
  end

  private

  def all_projects(current_user)
    projects = []

    projects << current_user.authorized_projects if current_user
    projects << Project.unscoped.public_to_user(current_user)

    projects
  end
end
