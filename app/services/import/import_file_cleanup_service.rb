# frozen_string_literal: true

module Import
  class ImportFileCleanupService
    LAST_MODIFIED = 72.hours
    BATCH_SIZE = 100

    def execute
      ImportExportUpload
        .with_import_file
        .updated_before(LAST_MODIFIED.ago)
        .each_batch(of: BATCH_SIZE) do |batch|
        batch.each do |upload|
          ::Gitlab::Import::RemoveImportFileWorker.perform_async(upload.id)
        end
      end
    end
  end
end
