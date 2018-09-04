module Gitlab
  module Geo
    module LogCursor
      module Events
        class RepositoryDeletedEvent
          include BaseEvent

          def process
            job_id = nil

            unless skippable?
              job_id = destroy_repository
              delete_project_registry_entries
            end

            log_event(job_id)
          end

          private

          def destroy_repository
            # Must always schedule, regardless of shard health
            ::Geo::RepositoryDestroyService.new(
              event.project_id,
              event.deleted_project_name,
              event.deleted_path,
              event.repository_storage_name
            ).async_execute
          end

          # rubocop: disable CodeReuse/ActiveRecord
          def delete_project_registry_entries
            ::Geo::ProjectRegistry.where(project_id: event.project_id).delete_all
          end
          # rubocop: enable CodeReuse/ActiveRecord

          def log_event(job_id)
            logger.event_info(
              created_at,
              'Deleted project',
              project_id: event.project_id,
              repository_storage_name: event.repository_storage_name,
              disk_path: event.deleted_path,
              skippable: skippable?,
              job_id: job_id
            )
          end
        end
      end
    end
  end
end
