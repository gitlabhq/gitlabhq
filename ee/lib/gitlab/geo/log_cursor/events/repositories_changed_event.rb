module Gitlab
  module Geo
    module LogCursor
      module Events
        class RepositoriesChangedEvent
          include BaseEvent

          def process
            return unless Gitlab::Geo.current_node.id == event.geo_node_id

            # Must always schedule, regardless of shard health
            job_id = ::Geo::RepositoriesCleanUpWorker.perform_in(1.hour, event.geo_node_id)
            log_event(job_id)
          end

          private

          def log_event(job_id)
            if job_id
              logger.info('Scheduled repositories clean up for Geo node', geo_node_id: event.geo_node_id, job_id: job_id)
            else
              logger.error('Could not schedule repositories clean up for Geo node', geo_node_id: event.geo_node_id)
            end
          end
        end
      end
    end
  end
end
