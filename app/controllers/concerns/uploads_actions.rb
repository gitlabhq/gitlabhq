# frozen_string_literal: true

module UploadsActions
  extend ActiveSupport::Concern
  include Gitlab::Utils::StrongMemoize
  include SendFileUpload

  UPLOAD_MOUNTS = %w(avatar attachment file logo header_logo favicon).freeze

  included do
    prepend_before_action :set_request_format_from_path_extension
  end

  def create
    uploader = UploadService.new(model, params[:file], uploader_class).execute

    respond_to do |format|
      if uploader
        format.json do
          render json: { link: uploader.to_h }
        end
      else
        format.json do
          render json: _('Invalid file.'), status: :unprocessable_entity
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

    # We need to reset caching from the applications controller to get rid of the no-store value
    headers['Cache-Control'] = ''
    headers['Pragma'] = ''

    ttl, directives = *cache_settings
    ttl ||= 0
    directives ||= { private: true, must_revalidate: true }

    expires_in ttl, directives

    file_uploader = [uploader, *uploader.versions.values].find do |version|
      version.filename == params[:filename]
    end

    return render_404 unless file_uploader

    workhorse_set_content_type!
    send_upload(file_uploader, attachment: file_uploader.filename, disposition: content_disposition)
  end

  def authorize
    set_workhorse_internal_api_content_type

    authorized = uploader_class.workhorse_authorize(
      has_length: false,
      maximum_size: Gitlab::CurrentSettings.max_attachment_size.megabytes.to_i)

    render json: authorized
  rescue SocketError
    render json: _("Error uploading file"), status: :internal_server_error
  end

  private

  # Based on ActionDispatch::Http::MimeNegotiation. We have an
  # initializer that monkey-patches this method out (so that repository
  # paths don't guess a format based on extension), but we do want this
  # behavior when serving uploads.
  def set_request_format_from_path_extension
    path = request.headers['action_dispatch.original_path'] || request.headers['PATH_INFO']

    if match = path&.match(/\.(\w+)\z/)
      format = Mime[match.captures.first]

      request.format = format.symbol if format
    end
  end

  def content_disposition
    if uploader.embeddable? || uploader.pdf?
      'inline'
    else
      'attachment'
    end
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

  # rubocop: disable CodeReuse/ActiveRecord
  def build_uploader_from_upload
    return unless uploader = build_uploader

    upload_paths = uploader.upload_paths(params[:filename])
    upload = Upload.find_by(model: model, uploader: uploader_class.to_s, path: upload_paths)
    upload&.retrieve_uploader
  end
  # rubocop: enable CodeReuse/ActiveRecord

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

  def embeddable?
    uploader && uploader.exists? && uploader.embeddable?
  end

  def find_model
    nil
  end

  def cache_settings
    []
  end

  def model
    strong_memoize(:model) { find_model }
  end

  def workhorse_authorize_request?
    action_name == 'authorize'
  end
end
