module EnvironmentHelper
  def environment_for_build(project, build)
    return unless build.environment

    project.environments.find_by(name: build.expanded_environment_name)
  end

  def environment_link_for_build(project, build)
    environment = environment_for_build(project, build)
    if environment
      link_to environment.name, namespace_project_environment_path(project.namespace, project, environment)
    else
      content_tag :span, build.expanded_environment_name
    end
  end

  def deployment_link(deployment)
    return unless deployment

    link_to "##{deployment.id}", [deployment.project.namespace.becomes(Namespace), deployment.project, deployment.deployable]
  end

  def last_deployment_link_for_environment_build(project, build)
    environment = environment_for_build(project, build)
    return unless environment

    deployment_link(environment.last_deployment)
  end
end
