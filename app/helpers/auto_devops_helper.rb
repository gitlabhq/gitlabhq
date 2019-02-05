# frozen_string_literal: true

module AutoDevopsHelper
  def show_auto_devops_callout?(project)
    Feature.get(:auto_devops_banner_disabled).off? &&
      show_callout?('auto_devops_settings_dismissed') &&
      can?(current_user, :admin_pipeline, project) &&
      project.has_auto_devops_implicitly_disabled? &&
      !project.repository.gitlab_ci_yml &&
      !project.ci_service
  end
end
