# frozen_string_literal: true

module Import
  module BulkImports
    # When a group or project is deleted, database-level `ON DELETE CASCADE`
    # then removes all records in the hierarchy down to and including
    # `BulkImports::ExportUpload`. There is no FK relation between `ExportUpload`
    # and `Upload` records, so those must be cleaned up at the code level.
    # We can leave the other records (`BulkImport::*`) intact, as they will be
    # removed by the FK cascade.
    class RemoveExportUploadsService
      # @param portable [Group, Project]
      def initialize(portable)
        @portable = portable
      end

      def execute
        exports.each do |export|
          next if export.upload.nil?

          # As `BulkImports::Export` and `BulkImports::ExportUpload` will be
          # removed by the foreign key cascade, we can't rely on them still
          # existing by the time this job executes. Consequently, we find and
          # pass each upload ID.
          export.upload.uploads.each do |upload|
            ::Import::BulkImports::RemoveExportUploadWorker.perform_async(upload.id)
          end
        end

        ServiceResponse.success
      end

      private

      attr_reader :portable

      def exports
        portable.bulk_import_exports
      end
    end
  end
end
