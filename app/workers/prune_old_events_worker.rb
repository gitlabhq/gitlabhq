class PruneOldEventsWorker
  include Sidekiq::Worker

  def perform
    # Contribution calendar shows maximum 12 months of events
    Event.delete(Event.unscoped.where('created_at < ?', (12.months + 1.day).ago).limit(10_000).pluck(:id))
  end
end
