class UploadsController < ApplicationController
  def show
    model = params[:model].camelize.constantize.find(params[:id])
    uploader = model.send(params[:mounted_as])

    return not_found! if model.respond_to?(:project) && !can?(current_user, :read_project, model.project)

    return redirect_to uploader.url unless uploader.file_storage?

    return not_found! unless uploader.file.exists?

    disposition = uploader.image? ? 'inline' : 'attachment'
    send_file uploader.file.path, disposition: disposition
  end
end
