module EnvironmentsHelper
  def environments_list_data
    {
      endpoint: project_environments_path(@project, format: :json)
    }
  end

  def operations_metrics_path(project, environment)
    return environment_metrics_path(environment) if environment

    empty_project_environments_path(project)
  end
end
