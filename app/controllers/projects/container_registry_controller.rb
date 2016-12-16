class Projects::ContainerRegistryController < Projects::ApplicationController
  before_action :verify_registry_enabled
  before_action :authorize_read_container_image!
  before_action :authorize_update_container_image!, only: [:destroy]
  layout 'project'

  def index
    @images = project.container_images
  end

  def destroy
    url = namespace_project_container_registry_index_path(project.namespace, project)

    if tag
      delete_tag(url)
    else
      if image.destroy
        redirect_to url
      else
        redirect_to url, alert: 'Failed to remove image'
      end
    end
  end

  private

  def verify_registry_enabled
    render_404 unless Gitlab.config.registry.enabled
  end

  def delete_tag(url)
    if tag.delete
      image.destroy if image.tags.empty?
      redirect_to url
    else
      redirect_to url, alert: 'Failed to remove tag'
    end
  end

  def image
    @image ||= project.container_images.find_by(id: params[:id])
  end

  def tag
    @tag ||= image.tag(params[:tag]) if params[:tag].present?
  end
end
