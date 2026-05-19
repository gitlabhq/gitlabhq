# frozen_string_literal: true

module Import
  module Offline
    module Imports
      class ObjectStorageFileDownloadStrategy < ::Import::BulkImports::FileDownloadStrategy
        include Gitlab::Utils::StrongMemoize

        # @param offline_configuration [Import::Offline::Configuration] Object storage configuration detail
        # @param object_key [String] Key for the file to fetch from the object storage bucket.
        def initialize(offline_configuration:, object_key:)
          @configuration = offline_configuration
          @object_key = object_key
        end

        def validate!
          validate_url!(offline_storage_client.request_url(object_key))
        end

        private

        attr_reader :configuration, :object_key

        def perform_download(filepath)
          bytes_downloaded = 0
          content_type_validated = false

          File.open(filepath, 'wb') do |file|
            offline_storage_client.stream(object_key) do |chunk, _remaining, _total|
              validate_gzip_magic_bytes!(chunk) unless content_type_validated
              content_type_validated = true

              bytes_downloaded += chunk.bytesize

              validate_size!(bytes_downloaded)

              file.write(chunk)
            end
          end
        rescue StandardError => e
          FileUtils.rm_f(filepath)

          raise e
        end

        def validate_gzip_magic_bytes!(chunk)
          return if chunk.b.start_with?("\x1F\x8B".b) # gzip magic bytes

          log_and_raise_error('Invalid content type')
        end

        def file_size_limit
          Gitlab::CurrentSettings.current_application_settings.bulk_import_max_download_file_size.megabytes
        end
        strong_memoize_attr :file_size_limit

        def offline_storage_client
          Import::Clients::ObjectStorage.new(
            provider: configuration.provider,
            bucket: configuration.bucket,
            credentials: configuration.object_storage_credentials
          )
        end
        strong_memoize_attr :offline_storage_client

        def log_error_params
          {
            object_key: object_key,
            provider: configuration.provider
          }
        end
      end
    end
  end
end
