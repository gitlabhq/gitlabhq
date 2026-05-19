# frozen_string_literal: true

module Import
  module Offline
    module ExportUploadable
      COMPRESSED_FILE_EXTENSION = ".gz"

      # For Offline Transfer, we skip the creation of `ExportUpload` records and
      # send the created file directly to the object storage associated with the
      # export.
      def upload_directly_to_object_storage
        export_configuration = export.offline_export.configuration

        client = offline_storage_client(export_configuration)
        object_key = offline_storage_filename(export_configuration)

        validate_upload_url!(client.request_url(object_key))

        client.store_file(object_key, compressed_filename)
      end

      private

      def offline_storage_client(configuration)
        Import::Clients::ObjectStorage.new(
          provider: configuration.provider,
          bucket: configuration.bucket,
          credentials: configuration.object_storage_credentials
        )
      end

      def offline_storage_filename(config)
        Import::Offline::ObjectKeyBuilder.new(config).upload_object_key(
          portable: portable,
          relation: export.relation,
          extension: extension,
          batch_number: export.batched? ? batch.batch_number : nil
        )
      end

      def extension
        "#{File.extname(exported_filename)}#{COMPRESSED_FILE_EXTENSION}"
      end

      def validate_upload_url!(url)
        ::Gitlab::HTTP_V2::UrlBlocker.validate!(
          url,
          **Import::Framework::UrlBlockerParams.new.to_h
        )
      end
    end
  end
end
