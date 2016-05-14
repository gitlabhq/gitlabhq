class Projects::ContainerRegistryController < Projects::ApplicationController
  before_action :authorize_read_container_image!
  before_action :authorize_update_container_image!, only: [:destroy]
  layout 'project'

  def index
    @tags = container_registry_repository.tags
  end

  def destroy
    if tag.delete
      redirect_to namespace_project_container_registry_index_path(project.namespace, project)
    else
      redirect_to namespace_project_container_registry_index_path(project.namespace, project), alert: 'Failed to remove tag'
    end
  end

  private

  def container_registry_repository
    @container_registry_repository ||= project.container_registry_repository
  end

  def tag
    @tag ||= container_registry_repository[params[:id]]
  end
end
