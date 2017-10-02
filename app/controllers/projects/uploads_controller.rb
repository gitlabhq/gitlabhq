class Projects::UploadsController < Projects::ApplicationController
  include UploadsActions

  skip_before_action :project, :repository,
    if: -> { action_name == 'show' && image_or_video? }

  before_action :authorize_upload_file!, only: [:create]

  private

  def uploader
    return @uploader if defined?(@uploader)

    namespace = params[:namespace_id]
    id = params[:project_id]

    file_project = Project.find_by_full_path("#{namespace}/#{id}")

    if file_project.nil?
      @uploader = nil
      return
    end

    @uploader = FileUploader.new(file_project, params[:secret])
    @uploader.retrieve_from_store!(params[:filename])

    @uploader
  end

  def image_or_video?
    uploader && uploader.exists? && uploader.image_or_video?
  end

  def uploader_class
    FileUploader
  end

  alias_method :model, :project
end
