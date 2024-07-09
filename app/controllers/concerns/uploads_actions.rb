# frozen_string_literal: true

module UploadsActions
  extend ActiveSupport::Concern
  include Gitlab::Utils::StrongMemoize
  include SendFileUpload

  # Starting with version 2, Markdown upload URLs use project / group IDs instead of paths
  ID_BASED_UPLOAD_PATH_VERSION = 2

  UPLOAD_MOUNTS = %w[avatar attachment file logo pwa_icon header_logo favicon screenshot].freeze

  included do
    prepend_before_action :set_request_format_from_path_extension
    rescue_from FileUploader::InvalidSecret, with: :render_404

    rescue_from ::Gitlab::PathTraversal::PathTraversalAttackError do
      head :bad_request
    end
  end

  def create
    uploader = UploadService.new(model, params[:file], uploader_class, uploaded_by_user_id: current_user&.id).execute

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
    Gitlab::PathTraversal.check_path_traversal!(params[:filename])

    return render_404 unless uploader&.exists?

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

    return unless match = path&.match(/\.(\w+)\z/)

    format = Mime[match.captures.first]

    request.format = format.symbol if format
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
    if uploader_mounted?
      model.public_send(upload_mount) # rubocop:disable GitlabSecurity/PublicSend
    else
      build_uploader_from_upload
    end
  end
  strong_memoize_attr :uploader

  # rubocop: disable CodeReuse/ActiveRecord
  def build_uploader_from_upload
    return unless uploader = build_uploader

    upload_paths = uploader.upload_paths(params[:filename])
    upload = Upload.find_by(model: model, uploader: uploader_class.to_s, path: upload_paths)
    upload&.retrieve_uploader
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def build_uploader
    return unless params[:secret] && params[:filename]

    uploader = uploader_class.new(model, secret: params[:secret])

    return unless uploader.model_valid?

    uploader
  end

  def embeddable?
    uploader && uploader.exists? && uploader.embeddable?
  end

  def bypass_auth_checks_on_uploads?
    return false if target_project && !target_project.public? && target_project.enforce_auth_checks_on_uploads?

    action_name == 'show' && embeddable?
  end

  def upload_version_at_least?(version)
    return unless uploader && uploader.upload

    uploader.upload.version >= version
  end

  def target_project
    nil
  end

  def find_model
    nil
  end

  def cache_settings
    []
  end

  def model
    find_model
  end
  strong_memoize_attr :model

  def workhorse_authorize_request?
    action_name == 'authorize'
  end
end
