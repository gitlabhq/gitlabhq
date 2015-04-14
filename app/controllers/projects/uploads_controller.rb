class Projects::UploadsController < Projects::ApplicationController
  layout 'project'

  skip_before_filter :project, :repository, :authenticate_user!, only: [:show]

  before_filter :authorize_uploads, only: [:show]

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
    uploader = get_file
    
    return not_found! if uploader.nil? || !uploader.file.exists?

    disposition = uploader.image? ? 'inline' : 'attachment'
    send_file uploader.file.path, disposition: disposition
  end

  def get_file
    namespace = params[:namespace_id]
    id = params[:project_id]

    file_project = Project.find_with_namespace("#{namespace}/#{id}")

    return nil if file_project.nil?

    uploader = FileUploader.new(file_project, params[:secret])
    uploader.retrieve_from_store!(params[:filename])

    uploader
  end

  def authorize_uploads
    uploader = get_file
    unless uploader && uploader.image?
      project
    end
  end
end
