# frozen_string_literal: true

class MigrateSidekiqQueuedJobs < Gitlab::Database::Migration[2.0]
  class SidekiqMigrateJobs
    LOG_FREQUENCY_QUEUES = 10

    attr_reader :logger, :mappings

    # mappings is a hash of WorkerClassName => target_queue_name
    def initialize(mappings, logger: nil)
      @mappings = mappings
      @logger = logger
    end

    # Migrates jobs from queues that are outside the mappings
    # rubocop: disable Cop/SidekiqRedisCall
    def migrate_queues
      routing_rules_queues = mappings.values.uniq
      logger&.info("List of queues based on routing rules: #{routing_rules_queues}")
      Sidekiq.redis do |conn|
        # Redis 6 supports conn.scan_each(match: "queue:*", type: 'list')
        conn.scan_each(match: "queue:*") do |key|
          # Redis 5 compatibility
          next unless conn.type(key) == 'list'

          queue_from = key.split(':', 2).last
          next if routing_rules_queues.include?(queue_from)

          logger&.info("Migrating #{queue_from} queue")

          migrated = 0
          while queue_length(queue_from) > 0
            begin
              if migrated >= 0 && migrated % LOG_FREQUENCY_QUEUES == 0
                logger&.info("Migrating from #{queue_from}. Total: #{queue_length(queue_from)}. Migrated: #{migrated}.")
              end

              job = conn.rpop "queue:#{queue_from}"
              job_hash = Sidekiq.load_json job
              next unless mappings.has_key?(job_hash['class'])

              destination_queue = mappings[job_hash['class']]
              job_hash['queue'] = destination_queue
              conn.lpush("queue:#{destination_queue}", Sidekiq.dump_json(job_hash))
              migrated += 1
            rescue JSON::ParserError
              logger&.error("Unmarshal JSON payload from SidekiqMigrateJobs failed. Job: #{job}")
              next
            end
          end
          logger&.info("Finished migrating #{queue_from} queue")
        end
      end
    end

    private

    def queue_length(queue_name)
      Sidekiq.redis do |conn|
        conn.llen("queue:#{queue_name}")
      end
    end
    # rubocop: enable Cop/SidekiqRedisCall
  end

  def up
    return if Gitlab.com?

    mappings = Gitlab::SidekiqConfig.worker_queue_mappings
    logger = ::Gitlab::BackgroundMigration::Logger.build
    SidekiqMigrateJobs.new(mappings, logger: logger).migrate_queues
  end

  def down
    # no-op
  end
end
