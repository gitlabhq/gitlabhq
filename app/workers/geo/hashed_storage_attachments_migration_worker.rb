module Geo
  class HashedStorageAttachmentsMigrationWorker
    include ApplicationWorker
    include GeoQueue

    def perform(project_id, old_attachments_path, new_attachments_path)
      Geo::HashedStorageAttachmentsMigrationService.new(
        project_id,
        old_attachments_path: old_attachments_path,
        new_attachments_path: new_attachments_path
      ).execute
    end
  end
end
