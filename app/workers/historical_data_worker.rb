class HistoricalDataWorker
  include Sidekiq::Worker
  include CronjobQueue

  def perform
    return if Gitlab::Geo.secondary?
    HistoricalData.track!
  end
end
