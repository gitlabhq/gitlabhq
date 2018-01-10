module UploadsActions
  include Gitlab::Utils::StrongMemoize

  def create
    # TODO why not pass a GitlabUploader instance
    link_to_file = UploadService.new(model, params[:file], uploader_class).execute

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

  # This should either find the @file and redirect to its URL
  def show
    return render_404 unless uploader.exists?

    # send to the remote URL
    redirect_to uploader.url unless uploader.file_storage?

    # or send the file
    disposition = uploader.image_or_video? ? 'inline' : 'attachment'
    expires_in 0.seconds, must_revalidate: true, private: true
    binding.pry
    send_file uploader.file.path, disposition: disposition
  end

  private

  def uploader_class
    uploader.class
  end

  def upload_mount
    mounted_as = params[:mounted_as]
    upload_mounts = %w(avatar attachment file logo header_logo)
    mounted_as if upload_mounts.include? mounted_as
  end

  # TODO: this method is too complex
  #
  def uploader
    @uploader ||= if upload_model_class < CarrierWave::Mount::Extension && upload_mount
                    model.public_send(upload_mount)
                  elsif upload_model_class == PersonalSnippet
                    find_upload(PersonalFileUploader)&.build_uploader || PersonalFileUploader.new(model)
                  else
                    find_upload(FileUploader)&.build_uploader || FileUploader.new(model)
                  end

  end

  def find_upload(uploader_class)
    return nil unless params[:secret] && params[:filename]

    upload_path = uploader_class.upload_path(params[:secret], params[:filename])
    Upload.where(uploader: uploader_class.to_s, path: upload_path)&.last
  end

  def image_or_video?
    uploader && uploader.exists? && uploader.image_or_video?
  end
end
