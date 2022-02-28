# frozen_string_literal: true

# Currently we run CarrierWave 1.3.1 which means we can not whitelist files
# by their content type through magic header parsing.
#
# This is a patch to hold us over until we get to CarrierWave 2 :) It's a mashup of
# CarrierWave's lib/carrierwave/uploader/content_type_whitelist.rb and
# lib/carrierwave/sanitized_file.rb
#
# Include this concern and add a content_type_whitelist method to get the same
# behavior as you would with CarrierWave 2.
#
# This is not an exact replacement as we don't override
# SanitizedFile#content_type but we do set the content_type attribute when we
# check the whitelist.
#
# Remove this after moving to CarrierWave 2, though on practical terms it shouldn't
# break anything if left for a while.
module ContentTypeWhitelist
  module Concern
    extend ActiveSupport::Concern

    private

    # CarrierWave calls this method as part of it's before :cache callbacks.
    # Here we override and extend CarrierWave's method that does not parse the
    # magic headers.
    def check_content_type_whitelist!(new_file)
      if content_type_whitelist
        content_type = mime_magic_content_type(new_file.path)

        unless whitelisted_content_type?(content_type)
          message = I18n.t(:"errors.messages.content_type_whitelist_error", allowed_types: Array(content_type_whitelist).join(", "))
          raise CarrierWave::IntegrityError, message
        end
      end
    end

    def whitelisted_content_type?(content_type)
      Array(content_type_whitelist).any? { |item| content_type =~ /#{item}/ }
    end

    def mime_magic_content_type(path)
      if path
        File.open(path) do |file|
          Gitlab::Utils::MimeType.from_io(file) || 'invalid/invalid'
        end
      end
    rescue Errno::ENOENT
      nil
    end
  end
end
