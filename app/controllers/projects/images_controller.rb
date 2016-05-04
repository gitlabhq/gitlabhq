class Projects::ImagesController < Projects::ApplicationController
  before_action :authorize_read_image!
  before_action :authorize_update_image!, only: [:destroy]
  before_action :tag, except: [:index]
  layout 'project'

  def index
    @tags = image_repository.tags
  end

  def destroy
    if tag.delete
      redirect_to namespace_project_images_path(project.namespace, project)
    else
      redirect_to namespace_project_images_path(project.namespace, project), alert: 'Failed to remove tag'
    end
  end

  private

  def image_repository
    @image_repository ||= project.image_repository
  end

  def tag
    @tag ||= image_repository[params[:id]]
  end
end
