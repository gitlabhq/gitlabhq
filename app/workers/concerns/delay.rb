module Delay
  # Progressive backoff. It's copied from Sidekiq as is
  def delay(retry_count = 0)
    (retry_count**4) + 15 + (rand(30) * (retry_count + 1))
  end
end
