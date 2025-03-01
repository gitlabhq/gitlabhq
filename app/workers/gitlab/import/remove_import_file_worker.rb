# frozen_string_literal: true

module Gitlab
  module Import
    class RemoveImportFileWorker
      include ApplicationWorker

      idempotent!
      feature_category :importers
      data_consistency :sticky

      def perform(upload_id)
        upload = ImportExportUpload.find_by_id(upload_id)

        return unless upload

        upload.remove_import_file!
        upload.save!

        logger.info(
          message: 'Removed ImportExportUpload import_file',
          project_id: upload.project_id,
          group_id: upload.group_id
        )
      end

      private

      def logger
        @logger ||= ::Import::Framework::Logger.build
      end
    end
  end
end
