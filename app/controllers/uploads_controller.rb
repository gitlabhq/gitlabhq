class UploadsController < ApplicationController
  def show
    model = params[:model].camelize.constantize.find(params[:id])
    uploader = model.send(params[:mounted_as])

    if uploader.file_storage?
      if !model.respond_to?(:project) || can?(current_user, :read_project, model.project)
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
