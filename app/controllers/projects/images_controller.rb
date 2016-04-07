class Projects::ImagesController < Projects::ApplicationController
  before_action :authorize_read_image!
  before_action :authorize_update_image!, only: [:destroy]
  before_action :tag, except: [:index]
  layout 'project'

  def index
    @tags = registry.tags
  end

  def show
    respond_to do |format|
      format.html
    end
  end

  def destroy
    registry.destroy_tag(params[:id].to_s)
    redirect_to namespace_project_images_path(project.namespace, project)
  end

  private

  def registry
    @registry ||= project.registry
  end

  def tag
    @tag ||= registry.tag(params[:id])
  end
end
