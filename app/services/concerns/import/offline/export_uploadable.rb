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
        client.store_file(
          offline_storage_filename(export_configuration),
          compressed_filename
        )
      end

      def offline_storage_client(configuration)
        Import::Clients::ObjectStorage.new(
          provider: configuration.provider,
          bucket: configuration.bucket,
          credentials: configuration.object_storage_credentials
        )
      end

      # - `group_1/self.json` - `self` relation (JSON format)
      # - `group_1/milestones.ndjson` - tree relation, single file
      # - `project_1/issues/batch_1.ndjson` - tree relation, batched
      # - `project_1/repository.tar.gz` - archive relation, single file
      # - `project_1/uploads/batch_1.tar.gz` - archive relation, batched
      def offline_storage_filename(config)
        portable_identifier = "#{portable.class.name.downcase}_#{portable.id}"

        filename_parts = []
        filename_parts << config.export_prefix
        filename_parts << portable_identifier

        if export.batched?
          filename_parts << export.relation
          filename_parts << "batch_#{batch.batch_number}#{extension}"
        else
          filename_parts << "#{export.relation}#{extension}"
        end

        filename_parts.join("/")
      end

      def extension
        "#{File.extname(exported_filename)}#{COMPRESSED_FILE_EXTENSION}"
      end
    end
  end
end
