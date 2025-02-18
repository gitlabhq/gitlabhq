# frozen_string_literal: true

module EnvironmentsHelper
  include ActionView::Helpers::AssetUrlHelper

  def environments_list_data
    {
      endpoint: project_environments_path(@project, format: :json)
    }
  end

  def environments_folder_list_view_data(project, folder)
    {
      "endpoint" => folder_project_environments_path(project, folder, format: :json),
      "folder_name" => folder,
      "project_path" => project.full_path,
      "help_page_path" => help_page_path("ci/environments/_index.md"),
      "can_read_environment" => can?(current_user, :read_environment, @project).to_s
    }
  end

  def can_destroy_environment?(environment)
    can?(current_user, :destroy_environment, environment)
  end
end

EnvironmentsHelper.prepend_mod_with('EnvironmentsHelper')
