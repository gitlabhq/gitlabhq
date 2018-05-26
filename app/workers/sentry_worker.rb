class SentryWorker
  include ApplicationWorker

  def perform(event_hash)
    # Sidekiq has converted the argument back into a Ruby hash object
    Raven.send_event(event_hash) # send_event takes a hash or a Raven::Event.
  end
end
