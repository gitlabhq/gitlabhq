module EnvironmentsHelper
  def environments_list_data()
    {
      endpoint: namespace_project_environments_path(@project.namespace, @project)
    }
  end
end
