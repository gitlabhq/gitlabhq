# frozen_string_literal: true

module Gitlab
  module ContentTypes
    extend self

    SAFE_CONTENT_TYPES = %w[
      application/octet-stream
      application/gzip
      application/zip
      application/x-7z-compressed
      application/x-xz
      application/x-debian-package
      application/java-archive
      application/vnd.android.package-archive
      application/x-apple-diskimage
      application/x-tar
      application/x-gtar
      application/x-bzip2
      application/x-iso9660-image
    ].freeze
    DEFAULT_CONTENT_TYPE = 'application/octet-stream'

    def sanitize_content_type(content_type)
      return content_type if SAFE_CONTENT_TYPES.include?(content_type)

      DEFAULT_CONTENT_TYPE
    end
  end
end
