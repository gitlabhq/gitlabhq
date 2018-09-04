module Gitlab
  module Geo
    module LogCursor
      module Events
        class UploadDeletedEvent
          include BaseEvent

          # rubocop: disable CodeReuse/ActiveRecord
          def process
            log_event
            ::Geo::FileRegistry.where(file_id: event.upload_id, file_type: event.upload_type).delete_all
          end
          # rubocop: enable CodeReuse/ActiveRecord

          private

          def log_event
            logger.event_info(
              created_at,
              'Deleted upload file',
              upload_id: event.upload_id,
              upload_type: event.upload_type,
              file_path: event.file_path,
              model_id: event.model_id,
              model_type: event.model_type)
          end
        end
      end
    end
  end
end
