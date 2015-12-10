class HistoricalDataWorker
  include Sidekiq::Worker

  def perform
    HistoricalData.track!
  end
end
