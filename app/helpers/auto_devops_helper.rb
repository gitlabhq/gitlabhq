module AutoDevopsHelper
  def show_auto_devops_callout?(project)
    show_callout?('auto_devops_settings_dismissed') &&
      can?(current_user, :admin_pipeline, project) &&
      !current_application_settings.auto_devops_enabled? &&
      project.auto_devops&.enabled.nil?
  end
end
