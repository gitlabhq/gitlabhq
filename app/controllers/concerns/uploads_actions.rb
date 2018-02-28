module UploadsActions
  include Gitlab::Utils::StrongMemoize

  UPLOAD_MOUNTS = %w(avatar attachment file logo header_logo).freeze

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
  #   - send the file directly
  #   - or redirect to its URL
  #
  def show
    return render_404 unless uploader&.exists?

    if uploader.file_storage?
      disposition = uploader.image_or_video? ? 'inline' : 'attachment'
      expires_in 0.seconds, must_revalidate: true, private: true

      send_file uploader.file.path, disposition: disposition
    else
      redirect_to uploader.url
    end
  end

  private

  def uploader_class
    raise NotImplementedError
  end

  def upload_mount
    mounted_as = params[:mounted_as]
    mounted_as if UPLOAD_MOUNTS.include?(mounted_as)
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
    uploader = uploader_class.new(model, secret: params[:secret])

    return nil unless uploader.model_valid?

    uploader.retrieve_from_store!(params[:filename])
    uploader
  end

  def image_or_video?
    uploader && uploader.exists? && uploader.image_or_video?
  end

  def find_model
    nil
  end

  def model
    strong_memoize(:model) { find_model }
  end
end
