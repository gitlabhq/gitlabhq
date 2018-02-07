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
    if missing_auto_devops_service?(project)
      params = {
        kubernetes: link_to('Kubernetes cluster', project_clusters_path(project))
      }

      if missing_auto_devops_domain?(project)
        _('Auto Review Apps and Auto Deploy need a domain name and a %{kubernetes} to work correctly.') % params
      else
        _('Auto Review Apps and Auto Deploy need a %{kubernetes} to work correctly.') % params
      end
    elsif missing_auto_devops_domain?(project)
      _('Auto Review Apps and Auto Deploy need a domain name to work correctly.')
    end
  end

  private

  def missing_auto_devops_domain?(project)
    !(project.auto_devops || project.build_auto_devops)&.has_domain?
  end

  def missing_auto_devops_service?(project)
    !project.deployment_platform&.active?
  end
end
