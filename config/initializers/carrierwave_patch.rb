# frozen_string_literal: true

require "carrierwave/storage/fog"

# This pulls in https://github.com/carrierwaveuploader/carrierwave/pull/2504 to support
# sending AWS S3 encryption headers when copying objects.
module CarrierWave
  module Storage
    class Fog < Abstract
      class File
        def copy_to(new_path)
          connection.copy_object(@uploader.fog_directory, file.key, @uploader.fog_directory, new_path, copy_to_options)
          CarrierWave::Storage::Fog::File.new(@uploader, @base, new_path)
        end

        def copy_to_options
          acl_header.merge(@uploader.fog_attributes)
        end
      end
    end
  end
end
