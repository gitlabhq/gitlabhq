class Projects::UploadsController < Projects::ApplicationController
  include UploadsActions

  # These will kick you out if you don't have access.
  skip_before_action :project, :repository,
    if: -> { action_name == 'show' && image_or_video? }

  before_action :authorize_upload_file!, only: [:create]

  private

  def upload_model_class
    Project
  end

  def uploader_class
    FileUploader
  end

  def find_model
    return @project if @project

    namespace = params[:namespace_id]
    id = params[:project_id]

    Project.find_by_full_path("#{namespace}/#{id}")
  end
end
