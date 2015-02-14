class Projects::UploadsController < Projects::ApplicationController
  layout 'project'

  before_filter :project

  def show
    folder_id = params[:folder_id]
    filename = params[:filename]
    
    uploader = FileUploader.new("#{Rails.root}/uploads","#{@project.path_with_namespace}/#{folder_id}")
    uploader.retrieve_from_store!(filename)

    disposition = uploader.image? ? 'inline' : 'attachment'
    send_file uploader.file.path, disposition: disposition
  end
end
