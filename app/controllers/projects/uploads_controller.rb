class Projects::UploadsController < Projects::ApplicationController
  layout 'project'

  before_filter :project

  def create
    link_to_file = ::Projects::UploadService.new(project, params[:file]).
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

    return redirect_to uploader.url unless uploader.file_storage?

    uploader.retrieve_from_store!(params[:filename])

    return not_found! unless uploader.file.exists?

    disposition = uploader.image? ? 'inline' : 'attachment'
    send_file uploader.file.path, disposition: disposition
  end
end
