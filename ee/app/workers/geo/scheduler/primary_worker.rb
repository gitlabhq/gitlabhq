module Geo
  module Scheduler
    class PrimaryWorker < Geo::Scheduler::BaseWorker
      def perform
        return unless Gitlab::Geo.primary?

        super
      end
    end
  end
end
