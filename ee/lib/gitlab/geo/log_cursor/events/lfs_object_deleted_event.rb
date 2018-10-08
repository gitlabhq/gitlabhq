module Gitlab
  module Geo
    module LogCursor
      module Events
        class LfsObjectDeletedEvent
          include BaseEvent

          def process
            # Must always schedule, regardless of shard health
            job_id = ::Geo::FileRegistryRemovalWorker.perform_async(:lfs, event.lfs_object_id)
            log_event(job_id)
          end

          private

          def log_event(job_id)
            logger.event_info(
              created_at,
              'Delete LFS object scheduled',
              oid: event.oid,
              file_id: event.lfs_object_id,
              file_path: event.file_path,
              job_id: job_id)
          end
        end
      end
    end
  end
end
