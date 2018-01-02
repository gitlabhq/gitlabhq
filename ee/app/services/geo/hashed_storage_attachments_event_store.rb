module Geo
  class HashedStorageAttachmentsEventStore < EventStore
    self.event_type = :hashed_storage_attachments_event

    private

    def build_event
      Geo::HashedStorageAttachmentsEvent.new(
        project: project,
        old_attachments_path: old_attachments_path,
        new_attachments_path: new_attachments_path
      )
    end

    def old_attachments_path
      params.fetch(:old_attachments_path)
    end

    def new_attachments_path
      params.fetch(:new_attachments_path)
    end
  end
end
