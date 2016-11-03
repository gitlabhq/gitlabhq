class EnvironmentEntity < Grape::Entity
  include RequestAwareEntity

  expose :id
  expose :name
  expose :state
  expose :external_url
  expose :environment_type
  expose :project, with: ProjectEntity
  expose :last_deployment, using: DeploymentEntity
  expose :stoppable?

  expose :environment_url do |environment|
    @urls.namespace_project_environment_url(
      environment.project.namespace,
      environment.project,
      environment)
  end

  expose :created_at, :updated_at
end
