# frozen_string_literal: true

module RepositorySettingsRedirect
  extend ActiveSupport::Concern

  def redirect_to_repository_settings(project, anchor: nil)
    redirect_to project_settings_repository_path(project, anchor: anchor)
  end
end
