module UploadsActions
  include Gitlab::Utils::StrongMemoize

  def create
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

  # This should either
  #   - find the file and redirect to its URL
  #   - send the file
  #
  def show
    return render_404 unless uploader.exists?

    # send to the remote URL
    redirect_to uploader.url unless uploader.file_storage?

    # or send the file
    disposition = uploader.image_or_video? ? 'inline' : 'attachment'
    expires_in 0.seconds, must_revalidate: true, private: true
    send_file uploader.file.path, disposition: disposition
  end

  private

  def uploader_class
    raise NotImplementedError
  end

  def upload_mount
    mounted_as = params[:mounted_as]
    upload_mounts = %w(avatar attachment file logo header_logo)
    mounted_as if upload_mounts.include? mounted_as
  end

  def uploader_mounted?
    upload_model_class < CarrierWave::Mount::Extension && !upload_mount.nil?
  end

  def uploader
    strong_memoize(:uploader) do
      if uploader_mounted?
        model.public_send(upload_mount) # rubocop:disable GitlabSecurity/PublicSend
      else
        build_uploader_from_upload || build_uploader_from_params
      end
    end
  end

  def build_uploader_from_upload
    return nil unless params[:secret] && params[:filename]

    upload_path = uploader_class.upload_path(params[:secret], params[:filename])
    upload = Upload.find_by(uploader: uploader_class.to_s, path: upload_path)
    upload&.build_uploader
  end

  def build_uploader_from_params
    uploader = uploader_class.new(model, params[:secret])
    uploader.retrieve_from_store!(params[:filename])
    uploader
  end

  def image_or_video?
    uploader && uploader.exists? && uploader.image_or_video?
  end
end
