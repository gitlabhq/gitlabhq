class UploadsController < ApplicationController
  skip_before_filter :authenticate_user!, :reject_blocked!
  before_filter :authorize_access

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

  def authorize_access
    unless params[:mounted_as] == 'avatar'
      authenticate_user! && reject_blocked!
    end
  end
end
