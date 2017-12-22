module Geo
  class SidekiqCronConfigWorker
    include ApplicationWorker
    include CronjobQueue

    def perform
      Gitlab::Geo::CronManager.new.execute
    end
  end
end
