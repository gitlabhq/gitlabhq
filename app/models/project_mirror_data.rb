class ProjectMirrorData < ActiveRecord::Base
  include Gitlab::CurrentSettings

  BACKOFF_PERIOD = 24.seconds
  JITTER = 6.seconds

  belongs_to :project

  validates :project, presence: true
  validates :next_execution_timestamp, presence: true

  before_validation on: :create do
    self.next_execution_timestamp = Time.now
  end

  def reset_retry_count!
    self.retry_count = 0
  end

  def increment_retry_count!
    self.retry_count += 1
  end

  # We schedule the next sync time based on the duration of the
  # last mirroring period and add it a fixed backoff period with a random jitter
  def set_next_execution_timestamp!
    timestamp = Time.now
    retry_factor = [1, self.retry_count].max
    delay = [base_delay(timestamp) * retry_factor, Gitlab::Mirror.max_delay].min
    delay = [delay, Gitlab::Mirror.min_delay].max

    self.next_execution_timestamp = timestamp + delay
  end

  def set_next_execution_to_now!
    self.update_attributes(next_execution_timestamp: Time.now)
  end

  private

  def base_delay(timestamp)
    duration = timestamp - self.last_update_started_at

    (BACKOFF_PERIOD + rand(JITTER)) * duration.seconds
  end
end
