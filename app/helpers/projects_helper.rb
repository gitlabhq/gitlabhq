module ProjectsHelper
  def grouper_project_members(project)
    @project.users_projects.sort_by(&:project_access).reverse.group_by(&:project_access)
  end
end

