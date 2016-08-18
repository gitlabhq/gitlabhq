class MoveToProjectFinder
  def initialize(user)
    @user = user
  end

  def execute(from_project, search: nil, offset_id: nil)
    projects = @user.projects_where_can_admin_issues
    projects = projects.search(search) if search.present?
    projects = projects.excluding_project(from_project)

    # to ask for Project#name_with_namespace
    projects.includes(namespace: :owner)
  end
end
