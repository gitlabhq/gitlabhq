module Gitlab
  module Geo
    module LogCursor
      module Events
        class UploadDeletedEvent
          include BaseEvent

          def process
            job_id = ::Geo::FileRegistryRemovalWorker.perform_async(event.upload_type, event.upload_id)
            log_event(job_id)
          end

          def log_event(job_id)
            logger.event_info(
              created_at,
              'Delete upload file scheduled',
              upload_id: event.upload_id,
              upload_type: event.upload_type,
              file_path: event.file_path,
              model_id: event.model_id,
              model_type: event.model_type,
              job_id: job_id)
          end
        end
      end
    end
  end
end
