class EnvironmentEntity < Grape::Entity
  include RequestAwareEntity
  include Gitlab::Routing.url_helpers

  expose :id
  expose :name
  expose :project, with: ProjectEntity
  expose :last_deployment,
    as: :deployment,
    using: API::Entities::Deployment

  expose :gitlab_path do |environment|
    namespace_project_environment_path(
      environment.project.namespace,
      environment.project,
      environment
    )
  end

  expose :can_read?

  def can_read?
    Ability.allowed?(request.user, :read_environment, @object)
  end
end
