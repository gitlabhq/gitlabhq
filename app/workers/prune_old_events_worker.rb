class PruneOldEventsWorker
  include Sidekiq::Worker

  def perform
    # Contribution calendar shows maximum 12 months of events
    Event.where('created_at < ?', (12.months + 1.day).ago).destroy_all
  end
end
