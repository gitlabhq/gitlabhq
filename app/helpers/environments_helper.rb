module EnvironmentsHelper
  def environments_list_data
    {
      endpoint: project_environments_path(@project, format: :json)
    }
  end

  def metrics_path(project, environment)
    return metrics_project_environment_path(project, environment) if environment

    empty_project_environments_path(project)
  end
end
