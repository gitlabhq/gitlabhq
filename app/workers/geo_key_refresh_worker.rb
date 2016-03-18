class GeoKeyRefreshWorker
  include Sidekiq::Worker

  sidekiq_options queue: :default, retry: 55

  sidekiq_retry_in do |count|
    count <= 30 ? linear_backoff_strategy(count) : geometric_backoff_strategy(count)
  end

  def perform(key_id, action)
    action = action.to_sym

    case action
    when :create
      # ActiveRecord::RecordNotFound when not found (so job will retry)
      key = Key.find(key_id)
      key.add_to_shell
    when :delete
      # ActiveRecord::RecordNotFound when not found (so job will retry)
      key = Key.find(key_id)
      key.remove_from_shell
    end
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
