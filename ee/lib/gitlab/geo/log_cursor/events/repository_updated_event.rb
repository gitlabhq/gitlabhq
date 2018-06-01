module Gitlab
  module Geo
    module LogCursor
      module Events
        class RepositoryUpdatedEvent
          include BaseEvent

          def process
            registry.save!

            job_id = enqueue_job_if_shard_healthy(event) do
              ::Geo::ProjectSyncWorker.perform_async(event.project_id, Time.now)
            end

            log_event(job_id)
          end

          private

          def registry
            @registry ||= find_or_initialize_registry(
              "resync_#{event.source}" => true,
              "#{event.source}_verification_checksum_sha" => nil,
              "#{event.source}_checksum_mismatch" => false,
              "last_#{event.source}_verification_failure" => nil
            )
          end

          def log_event(job_id)
            logger.event_info(
              created_at,
              'Repository update',
              project_id: event.project_id,
              source: event.source,
              resync_repository: registry.resync_repository,
              resync_wiki: registry.resync_wiki,
              job_id: job_id)
          end
        end
      end
    end
  end
end
