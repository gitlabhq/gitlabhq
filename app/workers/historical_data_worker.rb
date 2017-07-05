class HistoricalDataWorker
  include Sidekiq::Worker
  include CronjobQueue

  def perform
    return if License.current.nil? || License.current&.trial?

    HistoricalData.track!
  end
end
