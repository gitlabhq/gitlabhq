module EnvironmentHelper
  def environment_for_build(project, build)
    return unless build.environment

    environment_name = ExpandVariables.expand(build.environment, build.variables)
    project.environments.find_by(name: environment_name)
  end

  def environment_link_for_build(project, build)
    environment = environment_for_build(project, build)
    return unless environment

    link_to environment.name, namespace_project_environment_path(project.namespace, project, environment)
  end

  def deployment_link(project, deployment)
    return unless deployment

    link_to "##{deployment.id}", [deployment.project.namespace.becomes(Namespace), deployment.project, deployment.deployable]
  end
end
