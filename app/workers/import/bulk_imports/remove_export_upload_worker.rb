# frozen_string_literal: true

module Import
  module BulkImports
    class RemoveExportUploadWorker
      include ApplicationWorker

      data_consistency :delayed
      feature_category :importers
      idempotent!

      def perform(upload_id)
        upload = ::Upload.find_by_id(upload_id)
        return unless upload&.uploader == 'BulkImports::ExportUploader'

        upload.destroy!
      end
    end
  end
end
