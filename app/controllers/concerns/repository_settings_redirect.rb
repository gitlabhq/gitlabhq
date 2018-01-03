module RepositorySettingsRedirect
  extend ActiveSupport::Concern

  def redirect_to_repository_settings(project)
    redirect_to project_settings_repository_path(project)
  end
end
