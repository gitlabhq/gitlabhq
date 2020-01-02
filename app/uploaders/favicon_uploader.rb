# frozen_string_literal: true

class FaviconUploader < AttachmentUploader
  include UploadTypeCheck::Concern

  EXTENSION_WHITELIST = %w[png ico].freeze

  check_upload_type extensions: EXTENSION_WHITELIST

  def extension_whitelist
    EXTENSION_WHITELIST
  end

  private

  def filename_for_different_format(filename, format)
    filename.chomp(File.extname(filename)) + ".#{format}"
  end
end
