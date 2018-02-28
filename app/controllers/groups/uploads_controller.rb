class Groups::UploadsController < Groups::ApplicationController
  include UploadsActions

  skip_before_action :group, if: -> { action_name == 'show' && image_or_video? }

  before_action :authorize_upload_file!, only: [:create]

  private

  def show_model
    strong_memoize(:show_model) do
      group_id = params[:group_id]

      Group.find_by_full_path(group_id)
    end
  end

  def authorize_upload_file!
    render_404 unless can?(current_user, :upload_file, group)
  end

  def uploader
    strong_memoize(:uploader) do
      file_uploader = uploader_class.new(show_model, params[:secret])
      file_uploader.retrieve_from_store!(params[:filename])
      file_uploader
    end
  end

  def uploader_class
    NamespaceFileUploader
  end

  alias_method :model, :group
end
