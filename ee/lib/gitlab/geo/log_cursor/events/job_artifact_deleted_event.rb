module Gitlab
  module Geo
    module LogCursor
      module Events
        class JobArtifactDeletedEvent
          include BaseEvent

          def process
            # Must always schedule, regardless of shard health
            job_id = ::Geo::FileRegistryRemovalWorker.perform_async(:job_artifact, event.job_artifact_id)
            log_event(job_id)
          end

          private

          def log_event(job_id)
            logger.event_info(
              created_at,
              'Delete job artifact scheduled',
              file_id: event.job_artifact_id,
              file_path: event.file_path,
              job_id: job_id)
          end
        end
      end
    end
  end
end
