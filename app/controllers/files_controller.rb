class FilesController < ApplicationController
  def download
    model = params[:type].capitalize.constantize.find(params[:id])
    uploader = model.attachment

    if uploader.file_storage?
      if can?(current_user, :read_project, model.project)
        send_file uploader.file.path, disposition: 'attachment'
      else
        not_found!
      end
    else
      redirect_to uploader.url
    end
  end
end

