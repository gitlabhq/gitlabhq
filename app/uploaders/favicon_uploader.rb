# frozen_string_literal: true

class FaviconUploader < AttachmentUploader
  EXTENSION_WHITELIST = %w[png ico].freeze
  MIME_WHITELIST = %w[image/png image/vnd.microsoft.icon].freeze

  def extension_whitelist
    EXTENSION_WHITELIST
  end

  def content_type_whitelist
    MIME_WHITELIST
  end

  private

  def filename_for_different_format(filename, format)
    filename.chomp(File.extname(filename)) + ".#{format}"
  end
end
