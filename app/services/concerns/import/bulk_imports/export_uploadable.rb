# frozen_string_literal: true

module Import
  module BulkImports
    module ExportUploadable
      include Gitlab::ImportExport::CommandLineUtil

      delegate :export_path, to: :config
      delegate :exported_filename, to: :export_service

      def config
        @config ||= ::BulkImports::FileTransfer.config_for(portable)
      end

      def export_service
        @export_service ||= config.export_service_for(relation).new(portable, export_path, relation, user)
      end

      def compress_and_upload_export
        compress_exported_relation
        upload_compressed_file
      end

      def compress_exported_relation
        gzip(dir: export_path, filename: exported_filename)
      end

      def upload_compressed_file
        File.open(compressed_filename) { |file| upload.export_file = file }
        upload.save!
      end

      def exported_filepath
        File.join(export_path, exported_filename)
      end

      def compressed_filename
        File.join(export_path, "#{exported_filename}.gz")
      end
    end
  end
end
