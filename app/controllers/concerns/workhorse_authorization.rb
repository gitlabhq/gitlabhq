# frozen_string_literal: true

module WorkhorseAuthorization
  extend ActiveSupport::Concern
  include WorkhorseRequest

  included do
    skip_before_action :verify_authenticity_token, only: %i[authorize]
    before_action :verify_workhorse_api!, only: %i[authorize]
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

  def file_is_valid?(file)
    return false unless file.is_a?(::UploadedFile)

    file_extension_whitelist.include?(File.extname(file.original_filename).downcase.delete('.'))
  end

  def uploader_class
    raise NotImplementedError
  end

  def file_extension_whitelist
    ImportExportUploader::EXTENSION_WHITELIST
  end
end
