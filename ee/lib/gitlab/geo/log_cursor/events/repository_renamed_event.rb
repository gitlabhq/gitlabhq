module Gitlab
  module Geo
    module LogCursor
      module Events
        class RepositoryRenamedEvent
          include BaseEvent

          def process
            return unless event.project_id

            job_id = rename_repository unless skippable?
            log_event(job_id)
          end

          private

          def rename_repository
            # Must always schedule, regardless of shard health
            ::Geo::RenameRepositoryService.new(
              event.project_id,
              event.old_path_with_namespace,
              event.new_path_with_namespace
            ).async_execute
          end

          def log_event(job_id)
            logger.event_info(
              created_at,
              'Renaming project',
              project_id: event.project_id,
              old_path: event.old_path_with_namespace,
              new_path: event.new_path_with_namespace,
              skippable: skippable?,
              job_id: job_id)
          end
        end
      end
    end
  end
end
