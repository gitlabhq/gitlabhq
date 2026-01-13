# frozen_string_literal: true

module Projects
  module ImportExport
    class RemoveRelationExportUploadWorker
      include ApplicationWorker

      data_consistency :delayed
      feature_category :importers
      idempotent!

      def perform(upload_id)
        upload = ::Upload.find_by_id(upload_id)
        return unless upload&.uploader == 'ImportExportUploader'

        upload.destroy!
      end
    end
  end
end
