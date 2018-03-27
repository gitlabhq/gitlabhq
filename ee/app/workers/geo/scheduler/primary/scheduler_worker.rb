module Geo
  module Scheduler
    module Primary
      class SchedulerWorker < Geo::Scheduler::SchedulerWorker
        def perform
          return unless Gitlab::Geo.primary?

          super
        end
      end
    end
  end
end
