class EnvironmentEntity < Grape::Entity
  include RequestAwareEntity

  expose :id
  expose :name
  expose :state
  expose :external_url
  expose :environment_type
  expose :last_deployment, using: DeploymentEntity
  expose :stoppable?
  expose :has_terminals?, as: :has_terminals

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
    terminal_namespace_project_environment_path(
      environment.project.namespace,
      environment.project,
      environment)
  end

  expose :created_at, :updated_at
end
