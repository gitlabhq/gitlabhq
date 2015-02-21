class Projects::UploadsController < Projects::ApplicationController
  layout "project"

  before_filter :project

  def show
    path = File.join(project.path_with_namespace, params[:secret])
    uploader = FileUploader.new('uploads', path)

    uploader.retrieve_from_store!(params[:filename])

    if uploader.file.exists?
      # Right now, these are always images, so we can safely render them inline.
      send_file uploader.file.path, disposition: 'inline'
    else
      not_found!
    end
  end
end
