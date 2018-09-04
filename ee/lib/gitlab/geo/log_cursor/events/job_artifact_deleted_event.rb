module Gitlab
  module Geo
    module LogCursor
      module Events
        class JobArtifactDeletedEvent
          include BaseEvent

          def process
            return unless file_registry_job_artifacts.any? # avoid race condition

            # delete synchronously to ensure consistency
            if File.file?(file_path) && !delete_file(file_path)
              return # do not delete file from registry if deletion failed
            end

            log_event
            file_registry_job_artifacts.delete_all
          end

          private

          # rubocop: disable CodeReuse/ActiveRecord
          def file_registry_job_artifacts
            @file_registry_job_artifacts ||= ::Geo::JobArtifactRegistry.where(artifact_id: event.job_artifact_id)
          end
          # rubocop: enable CodeReuse/ActiveRecord

          def file_path
            @file_path ||= File.join(::JobArtifactUploader.root, event.file_path)
          end

          def log_event
            logger.event_info(
              created_at,
              'Deleted job artifact',
              file_id: event.job_artifact_id,
              file_path: file_path)
          end

          def delete_file(path)
            File.delete(path)
          rescue => ex
            logger.error("Failed to remove file", exception: ex.class.name, details: ex.message, filename: path)
            false
          end
        end
      end
    end
  end
end
