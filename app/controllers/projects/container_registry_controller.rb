class Projects::ContainerRegistryController < Projects::ApplicationController
  before_action :verify_registry_enabled
  before_action :authorize_read_container_image!
  before_action :authorize_update_container_image!, only: [:destroy]
  layout 'project'

  def index
    @tags = container_registry_repository.tags
  end

  def destroy
    url = namespace_project_container_registry_index_path(project.namespace, project)

    if tag.delete
      redirect_to url
    else
      redirect_to url, alert: 'Failed to remove tag'
    end
  end

  private

  def verify_registry_enabled
    render_404 unless Gitlab.config.registry.enabled
  end

  def container_registry_repository
    @container_registry_repository ||= project.container_registry_repository
  end

  def tag
    @tag ||= container_registry_repository.tag(params[:id])
  end
end
