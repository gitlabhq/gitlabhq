class EnvironmentEntity < Grape::Entity
  include RequestAwareEntity

  expose :id
  expose :name
  expose :state
  expose :external_url
  expose :environment_type
  expose :last_deployment, using: DeploymentEntity
  expose :stop_action?

  expose :environment_path do |environment|
    namespace_project_environment_path(
      environment.project.namespace,
      environment.project,
      environment)
  end

  expose :stop_path do |environment|
    stop_namespace_project_environment_path(
      environment.project.namespace,
      environment.project,
      environment)
  end

  expose :terminal_path, if: ->(environment, _) { environment.has_terminals? } do |environment|
    can?(request.user, :admin_environment, environment.project) &&
      terminal_namespace_project_environment_path(
        environment.project.namespace,
        environment.project,
        environment)
  end

  expose :created_at, :updated_at
end
