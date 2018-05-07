module Gitlab
  module Geo
    module LogCursor
      module Events
        class HashedStorageAttachmentsEvent
          include BaseEvent

          def process
            job_id = hashed_storage_attachments_migrate
            log_event(job_id)
          end

          private

          def hashed_storage_attachments_migrate
            # Must always schedule, regardless of shard health
            ::Geo::HashedStorageAttachmentsMigrationService.new(
              event.project_id,
              old_attachments_path: event.old_attachments_path,
              new_attachments_path: event.new_attachments_path
            ).async_execute
          end

          def log_event(job_id)
            logger.event_info(
              created_at,
              'Migrating attachments to hashed storage',
              project_id: event.project_id,
              old_attachments_path: event.old_attachments_path,
              new_attachments_path: event.new_attachments_path,
              job_id: job_id
            )
          end
        end
      end
    end
  end
end
