# frozen_string_literal: true

module Import
  module Offline
    module Exports
      class WriteMetadataService
        include Gitlab::ImportExport::CommandLineUtil
        include Gitlab::Utils::StrongMemoize

        METADATA_FILENAME = 'metadata'
        METADATA_EXTENSION = 'json'
        TMPDIR_SEGMENT = 'offline_exports'

        def initialize(offline_export)
          @offline_export = offline_export
        end

        def execute
          return unless offline_export && offline_export.started?
          return if offline_export.bulk_import_exports.for_status(::BulkImports::Export::FINISHED).empty?

          json_writer.write_attributes(METADATA_FILENAME, export_metadata_hash)
          compress_metadata_file
          upload_to_object_storage

          ServiceResponse.success
        ensure
          FileUtils.remove_entry(tmpdir_path) if strong_memoized?(:tmpdir_path)
        end

        private

        attr_reader :offline_export

        def export_metadata_hash
          {
            instance_version: Gitlab::VERSION,
            instance_enterprise: Gitlab.ee?,
            export_prefix: configuration.export_prefix,
            source_hostname: Gitlab.config.gitlab.url,
            entities_mapping: entities_mapping_hash
          }.deep_stringify_keys
        end

        def entities_mapping_hash
          group_entity_prefix_map = map_exported_entity_paths(offline_export.included_group_routes, type: :group)
          project_entity_prefix_map = map_exported_entity_paths(offline_export.included_project_routes, type: :project)

          (group_entity_prefix_map + project_entity_prefix_map).to_h
        end

        def map_exported_entity_paths(included_routes, type:)
          included_routes.map do |route|
            [route.path, "#{type}_#{route.source_id}"]
          end
        end

        def upload_to_object_storage
          client = Import::Clients::ObjectStorage.new(
            provider: configuration.provider,
            bucket: configuration.bucket,
            credentials: configuration.object_storage_credentials
          )

          compressed_path = File.join(tmpdir_path, compressed_filename)
          object_key = Import::Offline::ObjectKeyBuilder.new(configuration).metadata_object_key

          client.store_file(object_key, compressed_path)
        end

        def configuration
          offline_export.configuration
        end

        def compress_metadata_file
          gzip(dir: tmpdir_path, filename: filename_with_extension)
        end

        def json_writer
          ::Gitlab::ImportExport::Json::NdjsonWriter.new(tmpdir_path)
        end
        strong_memoize_attr :json_writer

        def tmpdir_path
          Dir.mktmpdir(TMPDIR_SEGMENT)
        end
        strong_memoize_attr :tmpdir_path

        def compressed_filename
          "#{filename_with_extension}#{ExportUploadable::COMPRESSED_FILE_EXTENSION}"
        end

        def filename_with_extension
          "#{METADATA_FILENAME}.#{METADATA_EXTENSION}"
        end
      end
    end
  end
end
