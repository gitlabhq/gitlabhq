class GeoBulkNotifyWorker
  include Sidekiq::Worker

  sidekiq_options queue: :default


  def perform
    return unless Gitlab::Geo.enabled?
    Geo::NotifyNodesService.new.execute
  end
end
