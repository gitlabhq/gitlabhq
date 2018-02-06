class MoveToProjectFinder
  PAGE_SIZE = 50

  def initialize(user)
    @user = user
  end

  def execute(from_project, search: nil, offset_id: nil)
    projects = @user.projects_where_can_admin_issues
    projects = projects.search(search) if search.present?
    projects = projects.excluding_project(from_project)
    projects = projects.order_id_desc

    # infinite scroll using offset
    projects = projects.where('projects.id < ?', offset_id) if offset_id.present?
    projects = projects.limit(PAGE_SIZE)

    # to ask for Project#name_with_namespace
    projects.includes(namespace: :owner)
  end
end
