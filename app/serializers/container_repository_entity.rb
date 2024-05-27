# frozen_string_literal: true

class ContainerRepositoryEntity < Grape::Entity
  include RequestAwareEntity

  expose :id, :name, :path, :location, :created_at, :status, :tags_count
  expose :expiration_policy_started_at, as: :cleanup_policy_started_at

  expose :tags_path do |repository|
    project_registry_repository_tags_path(project, repository, format: :json)
  end

  expose :destroy_path, if: ->(*) { can_destroy? } do |repository|
    project_container_registry_path(project, repository, format: :json)
  end

  private

  alias_method :repository, :object

  def project
    request.respond_to?(:project) ? request.project : object.project
  end

  def can_destroy?
    can?(request.current_user, :update_container_image, project)
  end
end
