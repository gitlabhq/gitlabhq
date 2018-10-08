# This monkey patches CarrierWave 1.2.3 to make Google Cloud Storage work with
# extra query parameters:
# https://github.com/carrierwaveuploader/carrierwave/pull/2332/files
module CarrierWave
  module Storage
    class Fog < Abstract
      class File
        def authenticated_url(options = {})
          if %w(AWS Google Rackspace OpenStack).include?(@uploader.fog_credentials[:provider])
            # avoid a get by using local references
            local_directory = connection.directories.new(key: @uploader.fog_directory)
            local_file = local_directory.files.new(key: path)
            expire_at = ::Fog::Time.now + @uploader.fog_authenticated_url_expiration
            case @uploader.fog_credentials[:provider]
            when 'AWS', 'Google'
              local_file.url(expire_at, options)
            when 'Rackspace'
              connection.get_object_https_url(@uploader.fog_directory, path, expire_at, options)
            when 'OpenStack'
              connection.get_object_https_url(@uploader.fog_directory, path, expire_at)
            else
              local_file.url(expire_at)
            end
          end
        end
      end
    end
  end
end
