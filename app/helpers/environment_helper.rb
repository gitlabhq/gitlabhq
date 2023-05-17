# frozen_string_literal: true

module EnvironmentHelper
  # rubocop: disable CodeReuse/ActiveRecord
  def environment_for_build(project, build)
    return unless build.environment

    project.environments.find_by(name: build.expanded_environment_name)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def environment_link_for_build(project, build)
    environment = environment_for_build(project, build)
    if environment
      link_to environment.name, project_environment_path(project, environment)
    else
      content_tag :span, build.expanded_environment_name
    end
  end

  def deployment_path(deployment)
    [deployment.project, deployment.deployable]
  end

  def deployment_link(deployment, text: nil)
    return unless deployment

    link_label = text || "##{deployment.iid}"

    link_to link_label, deployment_path(deployment)
  end

  def last_deployment_link_for_environment_build(project, build)
    environment = environment_for_build(project, build)
    return unless environment

    deployment_link(environment.last_deployment)
  end

  def render_deployment_status(deployment)
    status = deployment.status

    status_text =
      case status
      when 'created'
        s_('Deployment|created')
      when 'running'
        s_('Deployment|running')
      when 'success'
        s_('Deployment|success')
      when 'failed'
        s_('Deployment|failed')
      when 'canceled'
        s_('Deployment|canceled')
      when 'skipped'
        s_('Deployment|skipped')
      when 'blocked'
        s_('Deployment|blocked')
      end

    ci_icon_utilities = "gl-display-inline-flex gl-align-items-center gl-line-height-0 gl-px-3 gl-py-2 gl-rounded-base"
    klass = "ci-status ci-#{status.dasherize} #{ci_icon_utilities}"
    text = "#{ci_icon_for_status(status)} <span class=\"gl-ml-2\">#{status_text}</span>".html_safe

    if deployment.deployable
      link_to(text, deployment_path(deployment), class: klass)
    else
      content_tag(:span, text, class: klass)
    end
  end

  def environments_detail_data(user, project, environment)
    {
      name: environment.name,
      id: environment.id,
      project_full_path: project.full_path,
      external_url: environment.external_url,
      can_update_environment: can?(current_user, :update_environment, environment),
      can_destroy_environment: can_destroy_environment?(environment),
      can_stop_environment: can?(current_user, :stop_environment, environment),
      can_admin_environment: can?(current_user, :admin_environment, project),
      **environment_metrics_path(project, environment),
      environments_fetch_path: project_environments_path(project, format: :json),
      environment_edit_path: edit_project_environment_path(project, environment),
      environment_stop_path: stop_project_environment_path(project, environment),
      environment_delete_path: environment_delete_path(environment),
      environment_cancel_auto_stop_path: cancel_auto_stop_project_environment_path(project, environment),
      environment_terminal_path: terminal_project_environment_path(project, environment),
      has_terminals: environment.has_terminals?,
      is_environment_available: environment.available?,
      auto_stop_at: environment.auto_stop_at,
      graphql_etag_key: environment.etag_cache_key
    }
  end

  def environments_detail_data_json(user, project, environment)
    environments_detail_data(user, project, environment).to_json
  end

  def environment_metrics_path(project, environment)
    return {} if Feature.enabled?(:remove_monitor_metrics)

    { environment_metrics_path: project_metrics_dashboard_path(project, environment: environment) }
  end
end
