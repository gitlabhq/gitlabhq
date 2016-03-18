class UploadsController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :find_model, :authorize_access!

  def show
    uploader = @model.send(upload_mount)

    unless uploader.file_storage?
      return redirect_to uploader.url
    end

    unless uploader.file && uploader.file.exists?
      return render_404
    end

    disposition = uploader.image? ? 'inline' : 'attachment'
    send_file uploader.file.path, disposition: disposition
  end

  private

  def find_model
    unless upload_model && upload_mount
      return render_404
    end

    @model = upload_model.find(params[:id])
  end

  def authorize_access!
    authorized =
      case @model
      when Project
        can?(current_user, :read_project, @model)
      when Group
        can?(current_user, :read_group, @model)
      when Note
        can?(current_user, :read_project, @model.project)
      else
        # No authentication required for user avatars.
        true
      end

    return if authorized

    if current_user
      render_404
    else
      authenticate_user!
    end
  end

  def upload_model
    upload_models = {
      "user"    => User,
      "project" => Project,
      "note"    => Note,
      "group"   => Group,
      "appearance" => Appearance
    }

    upload_models[params[:model]]
  end

  def upload_mount
    upload_mounts = %w(avatar attachment file logo header_logo)

    if upload_mounts.include?(params[:mounted_as])
      params[:mounted_as]
    end
  end
end
