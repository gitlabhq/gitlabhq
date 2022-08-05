# frozen_string_literal: true

class FaviconUploader < AttachmentUploader
  EXTENSION_ALLOWLIST = %w[png ico].freeze
  MIME_ALLOWLIST = %w[image/png image/vnd.microsoft.icon].freeze

  def extension_whitelist
    EXTENSION_ALLOWLIST
  end

  def content_type_whitelist
    MIME_ALLOWLIST
  end

  private

  def filename_for_different_format(filename, format)
    filename.chomp(File.extname(filename)) + ".#{format}"
  end
end
