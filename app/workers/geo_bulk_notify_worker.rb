class GeoBulkNotifyWorker
  include Sidekiq::Worker

  sidekiq_options queue: :default

  def perform
    Geo::NotifyNodesService.new.execute
  end
end
