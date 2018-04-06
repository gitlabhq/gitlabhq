module UploadsActions
  include Gitlab::Utils::StrongMemoize
  include SendFileUpload

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

    expires_in 0.seconds, must_revalidate: true, private: true

    disposition = uploader.image_or_video? ? 'inline' : 'attachment'

    send_upload(uploader, attachment: uploader.filename, disposition: disposition)
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
    return unless uploader = build_uploader

    upload_paths = uploader.upload_paths(params[:filename])
    upload = Upload.find_by(uploader: uploader_class.to_s, path: upload_paths)
    upload&.build_uploader
  end

  def build_uploader_from_params
    return unless uploader = build_uploader

    uploader.retrieve_from_store!(params[:filename])
    uploader
  end

  def build_uploader
    return unless params[:secret] && params[:filename]

    uploader = uploader_class.new(model, secret: params[:secret])

    return unless uploader.model_valid?

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
