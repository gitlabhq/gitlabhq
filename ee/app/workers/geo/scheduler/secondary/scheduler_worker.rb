module Geo
  module Scheduler
    module Secondary
      class SchedulerWorker < Geo::Scheduler::SchedulerWorker
        def perform
          return unless Gitlab::Geo.geo_database_configured?
          return unless Gitlab::Geo.secondary?

          super
        end
      end
    end
  end
end
