module Geo
  module Scheduler
    module Primary
      class PerShardSchedulerWorker < Geo::Scheduler::PerShardSchedulerWorker
        def perform
          unless Gitlab::Geo.primary?
            log_info('Current node not a primary')
            return
          end

          super
        end
      end
    end
  end
end
