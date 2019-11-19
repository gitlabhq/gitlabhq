# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # This migration takes all legacy uploads (that were uploaded using AttachmentUploader)
    # and migrate them to the new (FileUploader) location (=under projects).
    #
    # We have dependencies (uploaders) in this migration because extracting code would add a lot of complexity
    # and possible errors could appear as the logic in the uploaders is not trivial.
    #
    # This migration will be removed in 13.0 in order to get rid of a migration that depends on
    # the application code.
    class LegacyUploadsMigrator
      include Database::MigrationHelpers

      def perform(start_id, end_id)
        Upload.where(id: start_id..end_id, uploader: 'AttachmentUploader', model_type: 'Note').find_each do |upload|
          LegacyUploadMover.new(upload).execute
        end
      end
    end
  end
end
