module Gitlab
  module Geo
    module LogCursor
      module Events
        class RepositoryUpdatedEvent
          include BaseEvent

          def process
            registry.repository_updated!(event.source, scheduled_at)

            job_id = enqueue_job_if_shard_healthy(event) do
              ::Geo::ProjectSyncWorker.perform_async(event.project_id, scheduled_at)
            end

            log_event(job_id)
          end

          private

          def log_event(job_id)
            logger.event_info(
              created_at,
              'Repository update',
              project_id: event.project_id,
              source: event.source,
              resync_repository: registry.resync_repository,
              resync_wiki: registry.resync_wiki,
              scheduled_at: scheduled_at,
              job_id: job_id)
          end

          def scheduled_at
            @scheduled_at ||= Time.now
          end
        end
      end
    end
  end
end
