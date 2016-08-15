class ProjectsFinder < UnionFinder
  def execute(current_user = nil, project_ids_relation = nil)
    segments = all_projects(current_user)
    segments.map! { |s| s.where(id: project_ids_relation) } if project_ids_relation

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
