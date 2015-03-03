class UploadsController < ApplicationController
  skip_before_filter :authenticate_user!, :reject_blocked!
  before_filter :authorize_access

  def show
    unless upload_model && upload_mount
      return not_found!
    end

    model = upload_model.find(params[:id])
    uploader = model.send(upload_mount)

    if model.respond_to?(:project) && !can?(current_user, :read_project, model.project)
      return not_found!
    end

    unless uploader.file_storage?
      return redirect_to uploader.url
    end

    unless uploader.file.exists?
      return not_found!
    end

    disposition = uploader.image? ? 'inline' : 'attachment'
    send_file uploader.file.path, disposition: disposition
  end

  private

  def authorize_access
    unless params[:mounted_as] == 'avatar'
      authenticate_user! && reject_blocked!
    end
  end

  def upload_model
    upload_models = {
      user: User,
      project: Project,
      note: Note,
      group: Group
    }

    upload_models[params[:model].to_sym]
  end

  def upload_mount
    upload_mounts = %w(avatar attachment file)

    if upload_mounts.include?(params[:mounted_as])
      params[:mounted_as]
    end
  end
end
