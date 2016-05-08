class Projects::ContainerRegistryController < Projects::ApplicationController
  before_action :authorize_read_image!
  before_action :authorize_update_image!, only: [:destroy]
  before_action :tag, except: [:index]
  layout 'project'

  def index
    @tags = container_registry.tags

    other_repository = container_registry.registry["gitlab/gitlab-test3"]
    container_registry.copy_to(other_repository)
  end

  def destroy
    if tag.delete
      redirect_to namespace_project_container_registry_index_path(project.namespace, project)
    else
      redirect_to namespace_project_container_registry_index_path(project.namespace, project), alert: 'Failed to remove tag'
    end
  end

  private

  def container_registry
    @container_registry ||= project.container_registry
  end

  def tag
    @tag ||= container_registry[params[:id]]
  end
end
