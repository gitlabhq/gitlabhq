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
          # fog-aws needs multipart uploads to copy files above 5 GB,
          # and it is currently the only Fog provider that supports
          # multithreaded uploads (https://github.com/fog/fog-aws/pull/579).
          # Multithreaded uploads are essential for copying large amounts of data
          # within the request timeout.
          if ::Feature.enabled?(:s3_multithreaded_uploads, type: :ops) && fog_provider == 'AWS'
            # AWS SDK uses 10 threads by default and a multipart chunk size of 10 MB
            file.concurrency = 10
            file.multipart_chunk_size = 10485760
            file.copy(@uploader.fog_directory, new_path, copy_to_options)
          else
            # Some Fog providers may issue a GET request (https://github.com/fog/fog-google/issues/512)
            # instead of a HEAD request after the transfer completes,
            # which might cause the file to be downloaded locally.
            # We fallback to the original copy_object for non-AWS providers.
            connection.copy_object(@uploader.fog_directory, file.key, @uploader.fog_directory, new_path, copy_to_options)
          end

          CarrierWave::Storage::Fog::File.new(@uploader, @base, new_path)
        end

        def copy_to_options
          acl_header.merge(@uploader.fog_attributes)
        end

        def authenticated_url(options = {})
          if %w[AWS Google AzureRM].include?(@uploader.fog_credentials[:provider])
            # avoid a get by using local references
            local_directory = connection.directories.new(key: @uploader.fog_directory)
            local_file = local_directory.files.new(key: path)
            expire_at = options[:expire_at] || (::Fog::Time.now + @uploader.fog_authenticated_url_expiration)
            case @uploader.fog_credentials[:provider]
            when 'AWS', 'Google', 'AzureRM'
              local_file.url(expire_at, options)
            else
              local_file.url(expire_at)
            end
          end
        end
      end
    end
  end
end
