# frozen_string_literal: true

class MigrateSidekiqQueuedAndFutureJobs < Gitlab::Database::Migration[2.2]
  milestone '16.10'
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  class SidekiqMigrateJobs
    LOG_FREQUENCY_QUEUES = 10
    LOG_FREQUENCY = 1000

    attr_reader :logger, :mappings

    # mappings is a hash of WorkerClassName => target_queue_name
    def initialize(mappings, logger: nil)
      @mappings = mappings
      @logger = logger
    end

    # Migrates jobs from queues that are outside the mappings
    # rubocop: disable Cop/SidekiqRedisCall -- for migration
    def migrate_queues
      routing_rules_queues = mappings.values.uniq
      logger&.info("List of queues based on routing rules: #{routing_rules_queues}")
      Sidekiq.redis do |conn|
        conn.scan("MATCH", "queue:*") do |key|
          next unless conn.type(key) == 'list'

          queue_from = key.split(':', 2).last
          next if routing_rules_queues.include?(queue_from)

          migrate_queue(conn, queue_from)
        end
      end
      logger&.info("Done migrating queued jobs.")
    end

    # Migrate jobs in SortedSets, i.e. scheduled and retry sets.
    def migrate_set(sidekiq_set)
      scanned = 0
      migrated = 0

      estimated_size = Sidekiq.redis { |c| c.zcard(sidekiq_set) }
      logger&.info("Processing #{sidekiq_set} set. Estimated size: #{estimated_size}.")

      Sidekiq.redis do |c|
        c.zscan(sidekiq_set) do |job, score|
          if scanned > 0 && scanned % LOG_FREQUENCY == 0
            logger&.info("In progress. Scanned records: #{scanned}. Migrated records: #{migrated}.")
          end

          scanned += 1

          job_hash = Gitlab::Json.load(job)
          destination_queue = mappings[job_hash['class']]

          unless mappings.has_key?(job_hash['class'])
            logger&.info("Skipping job from #{job_hash['class']}. No destination queue found.")
            next
          end

          next if job_hash['queue'] == destination_queue

          job_hash['queue'] = destination_queue

          migrated += migrate_job_in_set(c, sidekiq_set, job, score, job_hash)
        end
      end

      logger&.info("Done. Scanned records: #{scanned}. Migrated records: #{migrated}.")

      {
        scanned: scanned,
        migrated: migrated
      }
    end
    # rubocop: enable Cop/SidekiqRedisCall

    def migrate_job_in_set(conn, sidekiq_set, job, score, job_hash)
      removed = conn.zrem(sidekiq_set, job)

      conn.zadd(sidekiq_set, score, Gitlab::Json.dump(job_hash)) if removed > 0

      removed
    end

    private

    def migrate_queue(conn, queue_from)
      logger&.info("Migrating #{queue_from} queue")

      migrated = 0
      while queue_length(conn, queue_from) > 0
        begin
          if migrated >= 0 && migrated % LOG_FREQUENCY_QUEUES == 0
            logger&.info("Migrating from #{queue_from}. Total: #{queue_length(conn,
              queue_from)}. Migrated: #{migrated}.")
          end

          job = conn.rpop("queue:#{queue_from}")
          job_hash = update_job_hash(job)
          next unless job_hash

          conn.lpush("queue:#{job_hash['queue']}", Sidekiq.dump_json(job_hash))
          migrated += 1
        rescue JSON::ParserError
          logger&.error("Unmarshal JSON payload from SidekiqMigrateJobs failed. Job: #{job}")
          next
        end
      end

      logger&.info("Finished migrating #{queue_from} queue")
    end

    def update_job_hash(job)
      job_hash = Sidekiq.load_json(job)
      return unless mappings.has_key?(job_hash['class'])

      destination_queue = mappings[job_hash['class']]
      job_hash['queue'] = destination_queue
      job_hash
    end

    def queue_length(conn, queue_name)
      conn.llen("queue:#{queue_name}")
    end
  end

  def up
    return if Gitlab.com?

    mappings = Gitlab::SidekiqConfig.worker_queue_mappings
    logger = ::Gitlab::BackgroundMigration::Logger.build
    migrator = SidekiqMigrateJobs.new(mappings, logger: logger)

    # TODO: make shard-aware. See https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/3430
    Gitlab::SidekiqSharding::Validator.allow_unrouted_sidekiq_calls do
      migrator.migrate_queues
      %w[schedule retry].each { |set| migrator.migrate_set(set) }
    end
  end

  def down
    # no-op
  end
end
