class Projects::UploadsController < Projects::ApplicationController
  layout 'project'

  before_filter :project

  def create
    link_to_file = ::Projects::UploadService.new(repository, params[:file]).
      execute

    respond_to do |format|
      if link_to_file
        format.json do
          render json: { link: link_to_file }
        end
      else
        format.json do
          render json: 'Invalid file.', status: :unprocessable_entity
        end
      end
    end
  end

  def show
    uploader = FileUploader.new(project, params[:secret])

    if uploader.file_storage?
      uploader.retrieve_from_store!(params[:filename])

      if uploader.file.exists?
        disposition = uploader.image? ? 'inline' : 'attachment'
        send_file uploader.file.path, disposition: disposition
      else
        not_found!
      end
    else
      redirect_to uploader.url
    end
  end
end
