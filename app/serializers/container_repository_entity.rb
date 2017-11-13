class ContainerRepositoryEntity < Grape::Entity
  include RequestAwareEntity

  expose :id, :path, :location

  expose :tags_path do |repository|
    project_registry_repository_tags_path(project, repository, format: :json)
  end

  expose :destroy_path, if: -> (*) { can_destroy? } do |repository|
    project_container_registry_path(project, repository, format: :json)
  end

  private

  alias_method :repository, :object

  def project
    request.project
  end

  def can_destroy?
    can?(request.current_user, :update_container_image, project)
  end
end
