class GeoBulkNotifyWorker
  include Sidekiq::Worker
  include CronjobQueue

  def perform
    Geo::NotifyNodesService.new.execute
  end
end
