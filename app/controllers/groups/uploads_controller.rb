class Groups::UploadsController < Groups::ApplicationController
  include UploadsActions

  skip_before_action :group, if: -> { action_name == 'show' && image_or_video? }

  before_action :authorize_upload_file!, only: [:create]

  private

  def upload_model_class
    Group
  end

  def uploader_class
    NamespaceFileUploader
  end

  def find_model
    return @group if @group

    group_id = params[:group_id]

    Group.find_by_full_path(group_id)
  end

  def authorize_upload_file!
    render_404 unless can?(current_user, :upload_file, group)
  end
end
