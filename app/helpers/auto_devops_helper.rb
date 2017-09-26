module AutoDevopsHelper
  def show_auto_devops_callout?(project)
    Feature.get(:auto_devops_banner_disabled).off? &&
      show_callout?('auto_devops_settings_dismissed') &&
      can?(current_user, :admin_pipeline, project) &&
      project.has_auto_devops_implicitly_disabled? &&
      !project.repository.gitlab_ci_yml &&
      !project.ci_service
  end

  def auto_devops_warning_message(project)
    missing_domain = !project.auto_devops&.has_domain?
    missing_service = !project.kubernetes_service&.active?

    if missing_service
      params = {
        kubernetes: link_to('Kubernetes service', edit_project_service_path(project, 'kubernetes'))
      }

      if missing_domain
        _('Auto Review Apps and Auto Deploy need a domain name and the %{kubernetes} to work correctly.') % params
      else
        _('Auto Review Apps and Auto Deploy need the %{kubernetes} to work correctly.') % params
      end
    elsif missing_domain
      _('Auto Review Apps and Auto Deploy need a domain name to work correctly.')
    end
  end
end
