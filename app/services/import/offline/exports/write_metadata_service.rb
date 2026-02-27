# frozen_string_literal: true

module Import
  module Offline
    module Exports
      class WriteMetadataService
        include Gitlab::ImportExport::CommandLineUtil
        include Gitlab::Utils::StrongMemoize

        METADATA_FILENAME = 'metadata'
        METADATA_EXTENSION = 'json'
        TMPDIR = 'offline_exports'

        def initialize(offline_export)
          @offline_export = offline_export
        end

        def execute
          return unless offline_export && offline_export.started?
          return if offline_export.bulk_import_exports.for_status(::BulkImports::Export::FINISHED).empty?

          json_writer.write_attributes(METADATA_FILENAME, export_metadata_hash)
          compress_metadata_file

          # TODO: Upload compressed metadata directly to object storage bucket once direct upload implemented in
          #       https://gitlab.com/gitlab-org/gitlab/-/merge_requests/221351

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
            export_prefix: offline_export.configuration.export_prefix,
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

        def compress_metadata_file
          gzip(dir: tmpdir_path, filename: "#{METADATA_FILENAME}.#{METADATA_EXTENSION}")
        end

        def json_writer
          ::Gitlab::ImportExport::Json::NdjsonWriter.new(tmpdir_path)
        end
        strong_memoize_attr :json_writer

        def tmpdir_path
          Dir.mktmpdir(TMPDIR)
        end
        strong_memoize_attr :tmpdir_path
      end
    end
  end
end
