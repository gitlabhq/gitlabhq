class GeoKeyChangeNotifyWorker
  include Sidekiq::Worker

  sidekiq_options queue: :default, retry: 55

  sidekiq_retry_in do |count|
    count <= 30 ? linear_backoff_strategy(count) : geometric_backoff_strategy(count)
  end

  def perform(key_id, change)
    Geo::NotifyKeyChangeService.new(key_id, change).execute
  end

  private

  def linear_backoff_strategy(count)
    rand(1..20) + count
  end

  def geometric_backoff_strategy(count)
    # This strategy is based on the original one from sidekiq
    count = count-30 # we must start counting after 30
    (count ** 4) + 15 + (rand(30)*(count+1))
  end
end
