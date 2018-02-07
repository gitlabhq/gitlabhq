module Geo
  module Scheduler
    class SecondaryWorker < Geo::Scheduler::BaseWorker
      def perform
        return unless Gitlab::Geo.geo_database_configured?
        return unless Gitlab::Geo.secondary?

        super
      end
    end
  end
end
