# frozen_string_literal: true

module Gitlab
  class SidekiqMigrateJobs
    LOG_FREQUENCY = 1_000

    attr_reader :sidekiq_set, :logger

    def initialize(sidekiq_set, logger: nil)
      @sidekiq_set = sidekiq_set
      @logger = logger
    end

    # mappings is a hash of WorkerClassName => target_queue_name
    def execute(mappings)
      source_queues_regex = Regexp.union(mappings.keys)
      cursor = 0
      scanned = 0
      migrated = 0

      estimated_size = Sidekiq.redis { |c| c.zcard(sidekiq_set) }
      logger&.info("Processing #{sidekiq_set} set. Estimated size: #{estimated_size}.")

      begin
        cursor, jobs = Sidekiq.redis { |c| c.zscan(sidekiq_set, cursor) }

        jobs.each do |(job, score)|
          if scanned > 0 && scanned % LOG_FREQUENCY == 0
            logger&.info("In progress. Scanned records: #{scanned}. Migrated records: #{migrated}.")
          end

          scanned += 1

          next unless job.match?(source_queues_regex)

          job_hash = Sidekiq.load_json(job)
          destination_queue = mappings[job_hash['class']]

          next unless mappings.has_key?(job_hash['class'])
          next if job_hash['queue'] == destination_queue

          job_hash['queue'] = destination_queue

          migrated += migrate_job(job, score, job_hash)
        end
      end while cursor.to_i != 0

      logger&.info("Done. Scanned records: #{scanned}. Migrated records: #{migrated}.")

      {
        scanned: scanned,
        migrated: migrated
      }
    end

    private

    def migrate_job(job, score, job_hash)
      Sidekiq.redis do |connection|
        removed = connection.zrem(sidekiq_set, job)

        if removed
          connection.zadd(sidekiq_set, score, Sidekiq.dump_json(job_hash))

          1
        else
          0
        end
      end
    end
  end
end
