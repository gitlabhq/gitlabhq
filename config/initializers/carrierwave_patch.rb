# frozen_string_literal: true

require "carrierwave/storage/fog"

# This pulls in https://github.com/carrierwaveuploader/carrierwave/pull/2504 to support
# sending AWS S3 encryption headers when copying objects.
#
# This patch also incorporates
# https://github.com/carrierwaveuploader/carrierwave/pull/2375 to
# provide Azure support
# and https://github.com/carrierwaveuploader/carrierwave/pull/2397 to
# support custom expire_at. This is already in CarrierWave v2.1.x, but
# upgrading this gem is a significant task:
# https://gitlab.com/gitlab-org/gitlab/-/issues/216067
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

        def authenticated_url(options = {})
          if %w[AWS Google Rackspace OpenStack AzureRM].include?(@uploader.fog_credentials[:provider])
            # avoid a get by using local references
            local_directory = connection.directories.new(key: @uploader.fog_directory)
            local_file = local_directory.files.new(key: path)
            expire_at = options[:expire_at] || ::Fog::Time.now + @uploader.fog_authenticated_url_expiration
            case @uploader.fog_credentials[:provider]
            when 'AWS', 'Google'
              # Older versions of fog-google do not support options as a parameter
              if url_options_supported?(local_file)
                local_file.url(expire_at, options)
              else
                warn "Options hash not supported in #{local_file.class}. You may need to upgrade your Fog provider."
                local_file.url(expire_at)
              end
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
