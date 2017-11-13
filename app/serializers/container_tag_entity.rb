class ContainerTagEntity < Grape::Entity
  include RequestAwareEntity

  expose :name, :location, :revision, :short_revision, :total_size, :created_at

  expose :destroy_path, if: -> (*) { can_destroy? } do |tag|
    project_registry_repository_tag_path(project, tag.repository, tag.name)
  end

  private

  alias_method :tag, :object

  def project
    request.project
  end

  def can_destroy?
    # TODO: We check permission against @project, not tag,
    # as tag is no AR object that is attached to project
    can?(request.current_user, :update_container_image, project)
  end
end
