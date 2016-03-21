class GeoKeyChangeNotifyWorker
  include Sidekiq::Worker
  include GeoDynamicBackoff

  sidekiq_options queue: :default

  def perform(key_id, key, action)
    Geo::NotifyKeyChangeService.new(key_id, key, action).execute
  end
end
