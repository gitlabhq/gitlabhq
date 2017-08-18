module EnvironmentHelper
  def environment_for_build(project, build)
    return unless build.environment

    project.environments.find_by(name: build.expanded_environment_name)
  end

  def environment_link_for_build(project, build)
    environment = environment_for_build(project, build)
    if environment
      link_to environment.name, project_environment_path(project, environment)
    else
      content_tag :span, build.expanded_environment_name
    end
  end

  def deployment_link(deployment, text: nil)
    return unless deployment

    link_label = text ? text : "##{deployment.iid}"

    link_to link_label, [deployment.project.namespace.becomes(Namespace), deployment.project, deployment.deployable]
  end

  def last_deployment_link_for_environment_build(project, build)
    environment = environment_for_build(project, build)
    return unless environment

    deployment_link(environment.last_deployment)
  end
end
