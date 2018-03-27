module Geo
  module Scheduler
    module Primary
      class PerShardSchedulerWorker < Geo::Scheduler::PerShardSchedulerWorker
        def perform
          return unless Gitlab::Geo.primary?

          super
        end
      end
    end
  end
end
