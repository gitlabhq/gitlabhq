module EnvironmentsHelper
  def environments_list_data
    {
      endpoint: project_environments_path(@project, format: :json)
    }
  end
end
