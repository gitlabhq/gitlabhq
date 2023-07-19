# frozen_string_literal: true

class RedisMigrationWorker
  include ApplicationWorker

  idempotent!
  data_consistency :delayed
  feature_category :redis
  urgency :throttled
  loggable_arguments 0

  SCAN_START_STOP = '0'

  def perform(job_class_name, cursor, options = {})
    migrator = self.class.fetch_migrator!(job_class_name)

    scan_size = options[:scan_size] || 1000
    deadline = Time.now.utc + 3.minutes

    while Time.now.utc < deadline
      cursor, keys = migrator.redis.scan(cursor, match: migrator.scan_match_pattern, count: scan_size)

      migrator.perform(keys) if keys.any?

      sleep(0.01)
      break if cursor == SCAN_START_STOP
    end

    self.class.perform_async(job_class_name, cursor, options) unless cursor == SCAN_START_STOP
  end

  class << self
    def fetch_migrator!(job_class_name)
      job_class = "Gitlab::BackgroundMigration::Redis::#{job_class_name}".safe_constantize
      raise NotImplementedError, "#{job_class_name} does not exist" if job_class.nil?

      job_class.new
    end
  end
end
