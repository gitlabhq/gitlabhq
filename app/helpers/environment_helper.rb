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
      end

    klass = "ci-status ci-#{status.dasherize}"
    text = "#{ci_icon_for_status(status)} #{status_text}".html_safe

    if deployment.deployable
      link_to(text, deployment_path(deployment), class: klass)
    else
      content_tag(:span, text, class: klass)
    end
  end
end
