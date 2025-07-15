# frozen_string_literal: true
require 'magic'
require 'mime/types'

# This wraps calls to a gem which support mime type detection.
# We use the `ruby-magic` gem instead of `mimemagic` due to licensing issues
module Gitlab
  module Utils
    class MimeType
      class << self
        def from_io(io)
          return unless io.is_a?(IO) || io.is_a?(StringIO)

          mime_type = File.magic(io, Magic::MIME_TYPE)
          mime_type == 'inode/x-empty' ? nil : mime_type
        end

        def from_string(string)
          return unless string.is_a?(String)

          string.type
        end

        def from_filename(filename, default: 'application/octet-stream', log_enabled: false)
          return default unless filename.is_a?(String)

          types = ::MIME::Types.type_for(filename)
          content_type = types.any? ? types.first.content_type : default

          if log_enabled
            # Temporarily log the detected content types as JSON to build the allowed content type list
            # When we remove this line, `log_enabled` needs to be removed as well
            # https://gitlab.com/gitlab-org/gitlab/-/issues/444768
            ::Gitlab::AppJsonLogger.info(determined_content_type: content_type)
          end

          content_type
        end
      end
    end
  end
end
