module Delay
  # Progressive backoff. It's copied from Sidekiq as is
  def delay(retry_count = 0)
    (retry_count**4) + 15 + (rand(30) * (retry_count + 1))
  end

  # To prevent the retry time from storing invalid dates in the database,
  # cap the max time to a week plus some random jitter value.
  def next_retry_time(retry_count)
    proposed_time = Time.now + delay(retry_count).seconds
    max_future_time = Time.now + 7.days + delay(1).seconds

    [proposed_time, max_future_time].min
  end
end
