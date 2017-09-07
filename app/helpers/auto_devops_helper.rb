module AutoDevopsHelper
  def show_auto_devops_callout?(project)
    show_callout?('auto_devops_settings_dismissed') &&
      can?(current_user, :admin_pipeline, project) &&
      project.has_auto_devops_implicitly_disabled?
  end
end
