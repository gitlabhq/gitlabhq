module Geo
  class EventLog < ActiveRecord::Base
    include Geo::Model
    include ::EachBatch

    belongs_to :repository_created_event,
      class_name: 'Geo::RepositoryCreatedEvent',
      foreign_key: :repository_created_event_id

    belongs_to :repository_updated_event,
      class_name: 'Geo::RepositoryUpdatedEvent',
      foreign_key: :repository_updated_event_id

    belongs_to :repository_deleted_event,
      class_name: 'Geo::RepositoryDeletedEvent',
      foreign_key: :repository_deleted_event_id

    belongs_to :repository_renamed_event,
      class_name: 'Geo::RepositoryRenamedEvent',
      foreign_key: :repository_renamed_event_id

    belongs_to :repositories_changed_event,
      class_name: 'Geo::RepositoriesChangedEvent',
      foreign_key: :repositories_changed_event_id

    belongs_to :hashed_storage_migrated_event,
      class_name: 'Geo::HashedStorageMigratedEvent',
      foreign_key: :hashed_storage_migrated_event_id

    belongs_to :hashed_storage_attachments_event,
      class_name: 'Geo::HashedStorageAttachmentsEvent',
      foreign_key: :hashed_storage_attachments_event_id

    belongs_to :lfs_object_deleted_event,
      class_name: 'Geo::LfsObjectDeletedEvent',
      foreign_key: :lfs_object_deleted_event_id

    belongs_to :job_artifact_deleted_event,
      class_name: 'Geo::JobArtifactDeletedEvent',
      foreign_key: :job_artifact_deleted_event_id

    belongs_to :upload_deleted_event,
      class_name: 'Geo::UploadDeletedEvent',
      foreign_key: :upload_deleted_event_id

    def self.latest_event
      order(id: :desc).first
    end

    def event
      repository_created_event ||
        repository_updated_event ||
        repository_deleted_event ||
        repository_renamed_event ||
        repositories_changed_event ||
        hashed_storage_migrated_event ||
        hashed_storage_attachments_event ||
        lfs_object_deleted_event ||
        job_artifact_deleted_event ||
        upload_deleted_event
    end

    def project_id
      event.try(:project_id)
    end
  end
end
