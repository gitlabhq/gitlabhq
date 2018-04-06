module Geo
  module Scheduler
    module Secondary
      class SchedulerWorker < Geo::Scheduler::SchedulerWorker
        def perform
          unless Gitlab::Geo.geo_database_configured?
            log_info('Geo database not configured')
            return
          end

          unless Gitlab::Geo.secondary?
            log_info('Current node not a secondary')
            return
          end

          super
        end
      end
    end
  end
end
