module UploadsActions
  extend ActiveSupport::Concern

  include Gitlab::Utils::StrongMemoize
  include SendFileUpload

  UPLOAD_MOUNTS = %w(avatar attachment file logo header_logo favicon).freeze

  included do
    prepend_before_action :set_html_format, only: :show
  end

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

    uploaders = [uploader, *uploader.versions.values]
    uploader = uploaders.find { |version| version.filename == params[:filename] }

    return render_404 unless uploader

    send_upload(uploader, attachment: uploader.filename, disposition: disposition)
  end

  def authorize
    set_workhorse_internal_api_content_type

    authorized = uploader_class.workhorse_authorize(
      has_length: false,
      maximum_size: Gitlab::CurrentSettings.max_attachment_size.megabytes.to_i)

    render json: authorized
  rescue SocketError
    render json: "Error uploading file", status: :internal_server_error
  end

  private

  # Explicitly set the format.
  # Otherwise rails 5 will set it from a file extension.
  # See https://github.com/rails/rails/commit/84e8accd6fb83031e4c27e44925d7596655285f7#diff-2b8f2fbb113b55ca8e16001c393da8f1
  def set_html_format
    request.format = :html
  end

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
