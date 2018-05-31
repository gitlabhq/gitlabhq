module Gitlab
  module Geo
    module LogCursor
      module Events
        class HashedStorageMigratedEvent
          include BaseEvent

          def process
            return unless event.project_id

            job_id = hashed_storage_migrate unless skippable?
            log_event(job_id)
          end

          private

          def hashed_storage_migrate
            # Must always schedule, regardless of shard health
            ::Geo::HashedStorageMigrationService.new(
              event.project_id,
              old_disk_path: event.old_disk_path,
              new_disk_path: event.new_disk_path,
              old_storage_version: event.old_storage_version
            ).async_execute
          end

          def log_event(job_id)
            logger.event_info(
              created_at,
              'Migrating project to hashed storage',
                project_id: event.project_id,
                old_storage_version: event.old_storage_version,
                new_storage_version: event.new_storage_version,
                old_disk_path: event.old_disk_path,
                new_disk_path: event.new_disk_path,
                skippable: skippable?,
                job_id: job_id)
          end
        end
      end
    end
  end
end
