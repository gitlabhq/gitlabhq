class EnvironmentEntity < Grape::Entity
  include RequestAwareEntity
  include Gitlab::Routing.url_helpers

  expose :id
  expose :name
  expose :project, with: ProjectEntity
  expose :last_deployment,
    as: :deployment,
    using: API::Entities::Deployment

  expose :environment_path

  def environment_path
    request.path
  end
end
