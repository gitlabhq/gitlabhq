class HistoricalDataWorker
  include Sidekiq::Worker

  def perform
    return if Gitlab::Geo.secondary?
    HistoricalData.track!
  end
end
