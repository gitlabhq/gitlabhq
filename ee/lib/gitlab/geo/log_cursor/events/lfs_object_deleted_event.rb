module Gitlab
  module Geo
    module LogCursor
      module Events
        class LfsObjectDeletedEvent
          include BaseEvent

          # rubocop: disable CodeReuse/ActiveRecord
          def process
            # Must always schedule, regardless of shard health
            job_id = ::Geo::FileRemovalWorker.perform_async(file_path)
            log_event(job_id)
            ::Geo::FileRegistry.lfs_objects.where(file_id: event.lfs_object_id).delete_all
          end
          # rubocop: enable CodeReuse/ActiveRecord

          private

          def file_path
            @file_path ||= File.join(LfsObjectUploader.root, event.file_path)
          end

          def log_event(job_id)
            logger.event_info(
              created_at,
              'Deleted LFS object',
              oid: event.oid,
              file_id: event.lfs_object_id,
              file_path: file_path,
              job_id: job_id)
          end
        end
      end
    end
  end
end
