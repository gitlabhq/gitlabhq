# frozen_string_literal: true

# Ensure that uploaded files are what they say they are for security and
# handling purposes. The checks are not 100% reliable so we err on the side of
# caution and allow by default, and deny when we're confident of a fail state.
#
# Include this concern, then call `check_upload_type` to check all
# uploads. Attach a `mime_type` or `extensions` parameter to only check
# specific upload types. Both parameters will be normalized to a MIME type and
# checked against the inferred MIME type of the upload content and filename
# extension.
#
# class YourUploader
#   include UploadTypeCheck::Concern
#   check_upload_type mime_types: ['image/png', /image\/jpe?g/]
#
#   # or...
#
#   check_upload_type extensions: ['png', 'jpg', 'jpeg']
# end
#
# The mime_types parameter can accept `NilClass`, `String`, `Regexp`,
# `Array[String, Regexp]`. This matches the CarrierWave `extension_whitelist`
# and `content_type_whitelist` family of behavior.
#
# The extensions parameter can accept `NilClass`, `String`, `Array[String]`.
module UploadTypeCheck
  module Concern
    extend ActiveSupport::Concern

    class_methods do
      def check_upload_type(mime_types: nil, extensions: nil)
        define_method :check_upload_type_callback do |file|
          magic_file = MagicFile.new(file.to_file)

          # Map file extensions back to mime types.
          if extensions
            mime_types = Array(mime_types) +
                         Array(extensions).map { |e| MimeMagic::EXTENSIONS[e] }
          end

          if mime_types.nil? || magic_file.matches_mime_types?(mime_types)
            check_content_matches_extension!(magic_file)
          end
        end
        before :cache, :check_upload_type_callback
      end
    end

    def check_content_matches_extension!(magic_file)
      return if magic_file.ambiguous_type?

      if magic_file.magic_type != magic_file.ext_type
        raise CarrierWave::IntegrityError, 'Content type does not match file extension'
      end
    end
  end

  # Convenience class to wrap MagicMime objects.
  class MagicFile
    attr_reader :file

    def initialize(file)
      @file = file
    end

    def magic_type
      @magic_type ||= MimeMagic.by_magic(file)
    end

    def ext_type
      @ext_type ||= MimeMagic.by_path(file.path)
    end

    def magic_type_type
      magic_type&.type
    end

    def ext_type_type
      ext_type&.type
    end

    def matches_mime_types?(mime_types)
      Array(mime_types).any? do |mt|
        magic_type_type =~ /\A#{mt}\z/ || ext_type_type =~ /\A#{mt}\z/
      end
    end

    # - Both types unknown or text/plain.
    # - Ambiguous magic type with text extension. Plain text file.
    # - Text magic type with ambiguous extension. TeX file missing extension.
    def ambiguous_type?
      (ext_type.to_s.blank? && magic_type.to_s.blank?) ||
      (magic_type.to_s.blank? && ext_type_type == 'text/plain') ||
      (ext_type.to_s.blank? && magic_type_type == 'text/plain')
    end
  end
end
