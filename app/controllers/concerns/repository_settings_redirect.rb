module RepositorySettingsRedirect
  extend ActiveSupport::Concern

  def redirect_to_repository_settings(project)
    redirect_to namespace_project_settings_repository_path(project.namespace, project)
  end
end
