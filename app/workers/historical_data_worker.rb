class HistoricalDataWorker
  include Sidekiq::Worker
  include Sidetiq::Schedulable

  recurrence { daily.hour_of_day(12) }

  def perform
    HistoricalData.track!
  end
end
